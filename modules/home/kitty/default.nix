{ username, ... }:
{
  home-manager.users.${username}.programs.kitty = {
    enable = true;
    settings = {
      font_family = "JetBrainsMono Nerd Font";
      font_size = 14;

      background = "#2e3440";
      foreground = "#d8dee9";
      cursor = "#d8dee9";
      cursor_text_color = "#2e3440";
      cursor_shape = "block";
      cursor_blink_interval = "0.5";
      selection_background = "#434c5e";
      selection_foreground = "#d8dee9";

      color0 = "#3b4252";
      color1 = "#bf616a";
      color2 = "#5e81ac";
      color3 = "#ebcb8b";
      color4 = "#88c0d0";
      color5 = "#81a1c1";
      color6 = "#8fbcbb";
      color7 = "#d8dee9";
      color8 = "#4c566a";
      color9 = "#bf616a";
      color10 = "#5e81ac";
      color11 = "#ebcb8b";
      color12 = "#88c0d0";
      color13 = "#81a1c1";
      color14 = "#8fbcbb";
      color15 = "#d8dee9";

      background_opacity = "0.9";
      background_blur = 50;
      window_padding_width = 10;
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      shell_integration = "enabled";

      macos_titlebar_color = "background";
      macos_option_as_alt = "yes";
      hide_window_decorations = "yes";

      clipboard_control = "write-clipboard write-primary read-clipboard read-primary";
    };
    keybindings = {
      "shift+enter" = "send_text all \\x1b[13;2u";
    };
  };
}
