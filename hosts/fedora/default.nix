{ username, ... }:
{
  imports = [ ../../modules/home/fedora.nix ];

  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
}
