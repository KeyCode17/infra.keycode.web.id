{ username, ... }:
{
  home-manager.users.${username}.home.file.".config/ghostty/config".text = ''
    font-family = JetBrainsMono Nerd Font
    font-size = 14

    window-padding-x = 10
    window-padding-y = 10
    window-decoration = true
    macos-titlebar-style = hidden
    background-opacity = 0.9
    background-blur-radius = 50

    clipboard-read = allow
    clipboard-write = allow
    clipboard-paste-protection = false

    background = 2e3440
    foreground = d8dee9

    cursor-color = d8dee9
    cursor-text = 2e3440
    cursor-style = block
    cursor-style-blink = true

    selection-background = 434c5e
    selection-foreground = d8dee9

    palette = 0=#3b4252
    palette = 1=#bf616a
    palette = 2=#5e81ac
    palette = 3=#ebcb8b
    palette = 4=#88c0d0
    palette = 5=#81a1c1
    palette = 6=#8fbcbb
    palette = 7=#d8dee9

    palette = 8=#4c566a
    palette = 9=#bf616a
    palette = 10=#5e81ac
    palette = 11=#ebcb8b
    palette = 12=#88c0d0
    palette = 13=#81a1c1
    palette = 14=#8fbcbb
    palette = 15=#d8dee9
  '';
}
