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
  ];

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };
}
