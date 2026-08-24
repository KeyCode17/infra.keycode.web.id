{
  config,
  pkgs,
  lib,
  username,
  enableTilingWM ? false,
  ...
}:
{
  imports = [
    ./system
    ./security
    ./packages
    ./defaults
    ./fonts
    ./homebrew
    ./services
    ./aerospace
    ./sketchybar
    ./network
    ./android.nix
  ];

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };
}
