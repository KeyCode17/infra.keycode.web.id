{ ... }:
{
  # Project-wide find & replace with a live diff preview before applying.
  # Defaults already use ripgrep (already in config.nix extraPackages) and
  # show the replace diff; only the intent is spelled out here.
  programs.nixvim.plugins.grug-far = {
    enable = true;
    settings = {
      engine = "ripgrep";
      engines.ripgrep.showReplaceDiff = true;
    };
  };
}
