{
  username,
  sshKeys,
  lib,
  ...
}:
{
  home-manager.users.${username} = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          extraOptions = {
            AddKeysToAgent = "yes";
          };
        };

        "porto" = {
          hostname = "103.197.191.30";
          user = "root";
        };

        # NixOS on dalang, behind CGNAT — reachable only over Tailscale.
        # Use the MagicDNS name, not the 100.x address: the tailnet IP changes
        # if the node is recreated, the name does not. (It was vps-722ec789
        # while the box still ran the provider's stock image; NixOS registers
        # itself as new-porto.)
        "new-porto" = {
          hostname = "new-porto";
          user = "root";
        };

        "renodis-dev" = {
          hostname = "198.211.107.163";
          user = "deployer";
          port = 2222;
        };

        "market" = {
          hostname = "187.77.121.129";
          user = "root";
        };

        # Hardened by /vps-harden: root SSH disabled, sshd moved off 22,
        # login restricted to the deployer account (AllowUsers deployer).
        "dakota" = {
          hostname = "165.227.83.86";
          user = "deployer";
          port = 23614;
        };

        "strata52.dev" = {
          hostname = "31.97.109.2";
          user = "root";
        };
      };
    };

    home.file.".ssh/authorized_keys" = lib.mkIf (sshKeys != [ ]) {
      text = lib.concatStringsSep "\n" sshKeys + "\n";
    };
  };
}
