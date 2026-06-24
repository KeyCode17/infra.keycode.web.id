{
  description = "nix-anywhere: unified Nix configuration for All (NixOS, macOS, Cloud VPS)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-app-util.url = "github:hraban/mac-app-util";

    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    clan-core = {
      url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
    };

  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      mac-app-util,
      determinate,
      nixvim,
      sops-nix,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      disko,
      clan-core,
      claude-code,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      defaultConfig = import ./config.nix;
      localConfigPath = ./config.local.nix;
      config =
        if builtins.pathExists localConfigPath then
          defaultConfig // (import localConfigPath)
        else
          defaultConfig;

      inherit (config)
        sshKeys
        enableLaravel
        enableRust
        enableVolta
        enableGolang
        fedoraUsername
        ;
      secretsFile = ./secrets/secrets.yaml;

      darwinSpecialArgs = {
        username = config.darwinUsername;
        enableTilingWM = config.darwinEnableTilingWM;
        inherit
          nixvim
          enableLaravel
          enableRust
          enableVolta
          enableGolang
          sshKeys
          sops-nix
          secretsFile
          clan-core
          claude-code
          mac-app-util
          ;
      };

      isDarwin =
        system:
        builtins.elem system [
          "x86_64-darwin"
          "aarch64-darwin"
        ];
      clan = clan-core.lib.clan {
        inherit self;
        meta.name = "keycode";
        meta.domain = "keycode.web.id";

        inventory = {
          services = { };
          machines.${config.darwinHostname}.machineClass = "darwin";
        };

        machines = {
          # Darwin (macOS)
          ${config.darwinHostname} = {
            nixpkgs.hostPlatform = "aarch64-darwin";
            imports = [
              determinate.darwinModules.default
              home-manager.darwinModules.home-manager
              mac-app-util.darwinModules.default
              nix-homebrew.darwinModules.nix-homebrew
              {
                nix-homebrew = {
                  enable = true;
                  enableRosetta = true;
                  user = config.darwinUsername;
                  autoMigrate = true;
                  mutableTaps = false;
                  taps = {
                    "homebrew/homebrew-core" = homebrew-core;
                    "homebrew/homebrew-cask" = homebrew-cask;
                  };
                };
              }
              ./modules/nix.nix
              ./modules/darwin
              ./modules/home/darwin.nix
              (
                { ... }:
                {
                  _module.args = darwinSpecialArgs;
                  # Local machine - requires SSH enabled on Mac (System Settings > Sharing > Remote Login)
                  clan.core.networking.targetHost = "keycode@localhost";
                }
              )
            ];
          };

        };
      };
    in
    {
      # Inherit configurations from clan
      inherit (clan.config) darwinConfigurations clanInternals;
      clan = clan.config;

      # Fedora (and other non-NixOS Linux): standalone home-manager.
      # Apply with: home-manager switch --flake .#<fedoraUsername>
      homeConfigurations.${fedoraUsername} = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        extraSpecialArgs = {
          username = fedoraUsername;
          inherit nixvim claude-code;
        };
        modules = [ ./hosts/fedora ];
      };

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              (writeShellApplication {
                name = "rebuild";
                runtimeInputs = if isDarwin system then [ nix-darwin.packages.${system}.darwin-rebuild ] else [ ];
                text =
                  if isDarwin system then
                    ''
                      echo "Rebuilding nix-darwin configuration..."
                      sudo darwin-rebuild switch --flake .
                      echo "Done!"
                    ''
                  else
                    ''
                      echo "Rebuilding NixOS configuration..."
                      sudo nixos-rebuild switch --flake .
                      echo "Done!"
                    '';
              })
              nixfmt
              clan-core.packages.${system}.clan-cli
            ];
          };
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
