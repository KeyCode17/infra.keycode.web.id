{ ... }:
{
  programs.nixvim.colorschemes.nord = {
    enable = true;
    settings = {
      contrast = true;
      borders = true;
      disable_background = true; # transparency (was rose-pine transparency=true)
      italic = true;
      bold = true;
      cursorline_transparent = false;
      enable_sidebar_background = false;
      uniform_diff_background = true;
    };
  };
}
