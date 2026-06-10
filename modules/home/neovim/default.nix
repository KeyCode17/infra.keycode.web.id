{
  username,
  nixvim,
  ...
}:
{
  home-manager.users.${username}.imports = [
    nixvim.homeModules.nixvim
    ./config.nix
  ];
}
