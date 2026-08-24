{
  pkgs,
  clan-core,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    gh
    glab
    (callPackage ../../../pkgs/rtk { })
    clan-core.packages.aarch64-darwin.clan-cli
    # claude-code intentionally not installed here: the native installer at
    # ~/.local/bin/claude shadows it on PATH and self-updates, so the nix copy
    # was dead weight with a second update path.
  ];
}
