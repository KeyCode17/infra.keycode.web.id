{
  username,
  enableLaravel ? false,
  enableRust ? false,
  enableVolta ? false,
  enableGolang ? false,
  sshKeys ? [ ],
  mac-app-util,
  lib,
  ...
}:
{
  imports = [
    ./packages/darwin.nix
    ./git
    ./starship
    ./zsh
    ./neovim

    ./tmux
    ./docker
    ./ssh
    ./sops
    ./kitty
    ./services
    ./wallpaper
    ./laravel
  ];

  nixpkgs.config.allowUnfree = true;
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.sharedModules = [ mac-app-util.homeManagerModules.default ];
  # NOTE: Ctrl+Space (tmux prefix) is freed up by disabling macOS's
  # "Select the previous input source" shortcut in System Settings → Keyboard →
  # Keyboard Shortcuts → Input Sources. That GUI toggle is the only reliable way;
  # a `defaults write com.apple.symbolichotkeys ...` does NOT make the live system
  # honor it (the plist changes but the shortcut keeps firing), so we don't try.
  home-manager.users.${username}.home.stateVersion = "24.11";
}
