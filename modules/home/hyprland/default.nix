{
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./eww.nix
    ./wofi.nix
    ./theme.nix
    ./hypridle.nix
  ];

  home-manager.users.${username} = {
    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;

      settings = {
        # Nord palette
        "$base" = "rgb(2e3440)";
        "$surface" = "rgb(3b4252)";
        "$overlay" = "rgb(3b4252)";
        "$muted" = "rgb(4c566a)";
        "$subtle" = "rgb(d8dee9)";
        "$text" = "rgb(d8dee9)";
        "$love" = "rgb(bf616a)";
        "$gold" = "rgb(ebcb8b)";
        "$rose" = "rgb(8fbcbb)";
        "$pine" = "rgb(5e81ac)";
        "$foam" = "rgb(88c0d0)";
        "$iris" = "rgb(81a1c1)";
        "$highlightMed" = "rgb(434c5e)";

        # auto-detect outputs; refine per-monitor after first boot via `hyprctl monitors`
        monitor = [
          ",preferred,auto,1.0"
        ];

        exec-once = [
          "hyprctl setcursor Bibata-Modern-Classic 32"
          "swaybg -c 2e3440"
          "eww open bar"
          "swayosd-server"
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
          "wl-paste --type text --watch cliphist store"
          "wl-paste --type image --watch cliphist store"
        ];

        general = {
          gaps_in = 8;
          gaps_out = 16;
          border_size = 1;
          "col.active_border" = "$iris $rose 45deg";
          "col.inactive_border" = "$highlightMed";
          layout = "dwindle";
          allow_tearing = false;
        };

        decoration = {
          rounding = 16;
          blur = {
            enabled = true;
            size = 8;
            passes = 3;
            new_optimizations = true;
            xray = true;
            vibrancy = 0.17;
            popups = true;
          };
          shadow = {
            enabled = true;
            range = 20;
            render_power = 3;
            color = "rgba(232730ee)";
          };
        };

        animations = {
          enabled = true;
          bezier = [
            "cute, 0.68, -0.55, 0.265, 1.55"
            "smooth, 0.25, 0.1, 0.25, 1"
            "bounce, 0.68, -0.6, 0.32, 1.6"
            "fadeBounce, 0.36, 0, 0.66, -0.56"
          ];
          animation = [
            "windows, 1, 5, bounce, slide"
            "windowsOut, 1, 5, cute, slide"
            "border, 1, 10, smooth"
            "borderangle, 1, 100, smooth, loop"
            "fade, 1, 5, smooth"
            "workspaces, 1, 5, smooth, slidefade 20%"
          ];
        };

        dwindle = {
          preserve_split = true;
          force_split = 2;
        };

        master = {
          new_status = "master";
        };

        input = {
          kb_layout = "us";
          kb_options = "caps:escape";
          follow_mouse = 1;
          sensitivity = 0.0;
          accel_profile = "adaptive";
          scroll_factor = 1.0;
          touchpad = {
            natural_scroll = true;
            tap-to-click = true;
            scroll_factor = 0.2;
          };
        };

        device = [
          {
            name = "asup1303:00-093a:3003-touchpad";
            sensitivity = 0.0;
            scroll_factor = 0.2;
          }
          {
            name = "asup1303:00-093a:3003-mouse";
            enabled = false;
          }
        ];

        cursor = {
          default_monitor = "";
        };

        env = [
          "XCURSOR_THEME,Bibata-Modern-Classic"
          "XCURSOR_SIZE,32"
          "NIXOS_OZONE_WL,1"
          "ELECTRON_OZONE_PLATFORM_HINT,auto"
          "MOZ_ENABLE_WAYLAND,1"
        ];

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
        };

        windowrule = [
          "float on, match:class ^(pavucontrol)$"
          "float on, match:class ^(nm-connection-editor)$"
          "float on, match:class ^(org.gnome.Calculator)$"
          "float on, match:title ^(Picture-in-Picture)$"
          "opacity 1.0 0.92, match:class ^(kitty)$"
          "opacity 1.0 0.92, match:class ^(Alacritty)$"
          "opacity 0.9, match:class ^(code)$"
        ];

        layerrule = [
          "blur on, ignore_alpha 0.3, match:namespace gtk-layer-shell"
          "blur on, ignore_alpha 0.3, match:namespace wofi"
        ];

        "$mod" = "SUPER";
        "$terminal" = "kitty";
        "$menu" = "wofi --show drun";
        "$browser" = "firefox";
        "$fileManager" = "nautilus";

        bind = [
          "$mod, Return, exec, $terminal"
          "$mod, Space, exec, $menu"
          "$mod, D, exec, $menu"
          "$mod, E, exec, $fileManager"
          "$mod, B, exec, $browser"

          "$mod SHIFT, Q, killactive"
          "$mod SHIFT, E, exit"
          "$mod, V, togglefloating"
          "$mod, F, fullscreen"
          "$mod SHIFT, F, fullscreen, 1"
          "$mod, T, layoutmsg, togglesplit"
          "$mod SHIFT, B, exec, eww open --toggle bar"
          "$mod SHIFT, T, exec, fix-touchpad"

          "$mod, left, movefocus, l"
          "$mod, right, movefocus, r"
          "$mod, up, movefocus, u"
          "$mod, down, movefocus, d"
          "$mod, H, movefocus, l"
          "$mod, L, movefocus, r"
          "$mod, K, movefocus, u"
          "$mod, J, movefocus, d"

          # move the focused window
          "$mod SHIFT, left, movewindow, l"
          "$mod SHIFT, right, movewindow, r"
          "$mod SHIFT, up, movewindow, u"
          "$mod SHIFT, down, movewindow, d"

          # resize the focused window
          "$mod CONTROL, left, resizeactive, -60 0"
          "$mod CONTROL, right, resizeactive, 60 0"
          "$mod CONTROL, up, resizeactive, 0 -60"
          "$mod CONTROL, down, resizeactive, 0 60"

          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod, 5, workspace, 5"
          "$mod, 6, workspace, 6"
          "$mod, 7, workspace, 7"
          "$mod, 8, workspace, 8"
          "$mod, 9, workspace, 9"
          "$mod, 0, workspace, 10"

          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
          "$mod SHIFT, 6, movetoworkspace, 6"
          "$mod SHIFT, 7, movetoworkspace, 7"
          "$mod SHIFT, 8, movetoworkspace, 8"
          "$mod SHIFT, 9, movetoworkspace, 9"
          "$mod SHIFT, 0, movetoworkspace, 10"

          "$mod, S, togglespecialworkspace, magic"
          "$mod SHIFT, S, movetoworkspace, special:magic"

          "$mod, mouse_down, workspace, e+1"
          "$mod, mouse_up, workspace, e-1"

          ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
          "SHIFT, Print, exec, grim - | wl-copy"

          "$mod, C, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"

          "$mod SHIFT, C, exec, hyprpicker -a"

          "$mod, X, exec, hyprlock"
          "$mod SHIFT, X, exec, caffeine"
        ];

        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        bindel = [
          ", XF86AudioRaiseVolume, exec, swayosd-client --output-volume +2"
          ", XF86AudioLowerVolume, exec, swayosd-client --output-volume -2"
        ];

        bindl = [
          ", XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
          ", XF86AudioMicMute, exec, swayosd-client --input-volume mute-toggle"
          ", switch:on:Lid Switch, exec, systemctl suspend"
        ];

        binde = [
          ", XF86MonBrightnessUp, exec, swayosd-client --brightness +2"
          ", XF86MonBrightnessDown, exec, swayosd-client --brightness -2"
        ];

        gesture = [
          "3, horizontal, workspace"
        ];
      };
    };

    home.file.".config/hypr/hyprlock.conf".text = ''
      general {
        disable_loading_bar = true
        grace = 0
        hide_cursor = true
        no_fade_in = false
      }

      background {
        monitor =
        color = rgba(2e3440ff)
      }

      label {
        monitor =
        text = cmd[update:1000] echo "$(date +'%H:%M')"
        color = rgba(216, 222, 233, 0.95)
        font_size = 120
        font_family = JetBrainsMono Nerd Font ExtraBold
        position = 0, 240
        halign = center
        valign = center
        shadow_passes = 2
        shadow_size = 6
        shadow_color = rgba(0, 0, 0, 0.45)
      }

      label {
        monitor =
        text = cmd[update:30000] echo "$(date +'%A, %d %B %Y')"
        color = rgba(129, 161, 193, 0.90)
        font_size = 18
        font_family = JetBrainsMono Nerd Font Medium
        position = 0, 120
        halign = center
        valign = center
      }

      shape {
        monitor =
        size = 130, 130
        color = rgba(59, 66, 82, 0.55)
        rounding = -1
        border_size = 2
        border_color = rgba(129, 161, 193, 0.60)
        position = 0, -30
        halign = center
        valign = center
        shadow_passes = 2
        shadow_size = 4
        shadow_color = rgba(0, 0, 0, 0.35)
      }

      label {
        monitor =
        text = 󰀄
        color = rgba(129, 161, 193, 0.90)
        font_size = 64
        font_family = JetBrainsMono Nerd Font
        position = 0, -30
        halign = center
        valign = center
      }

      label {
        monitor =
        text = $USER
        color = rgba(216, 222, 233, 0.95)
        font_size = 16
        font_family = JetBrainsMono Nerd Font Bold
        position = 0, -135
        halign = center
        valign = center
      }

      input-field {
        monitor =
        size = 320, 52
        outline_thickness = 2
        dots_size = 0.26
        dots_spacing = 0.30
        dots_center = true
        dots_rounding = -1
        outer_color = rgba(129, 161, 193, 0.55)
        inner_color = rgba(59, 66, 82, 0.65)
        font_color = rgba(216, 222, 233, 0.95)
        fade_on_empty = false
        rounding = 26
        check_color = rgba(136, 192, 208, 0.85)
        fail_color = rgba(191, 97, 106, 0.85)
        fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i>
        placeholder_text = <span font_family="JetBrainsMono Nerd Font" foreground="##81a1c1cc">  Enter password</span>
        hide_input = false
        position = 0, -200
        halign = center
        valign = center
        shadow_passes = 2
        shadow_size = 4
        shadow_color = rgba(0, 0, 0, 0.35)
      }

      label {
        monitor =
        text = cmd[update:60000] echo "  $(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)%"
        color = rgba(129, 161, 193, 0.75)
        font_size = 12
        font_family = JetBrainsMono Nerd Font
        position = -20, 20
        halign = right
        valign = bottom
      }

      label {
        monitor =
        text = cmd[update:30000] echo "  $(nmcli -t -f active,ssid dev wifi | awk -F: '/^yes/{print $2; exit}' || echo 'offline')"
        color = rgba(129, 161, 193, 0.75)
        font_size = 12
        font_family = JetBrainsMono Nerd Font
        position = 20, 20
        halign = left
        valign = bottom
      }
    '';

    services.mako = {
      enable = true;
      settings = {
        background-color = "#3b4252";
        text-color = "#d8dee9";
        border-color = "#81a1c1";
        border-size = 3;
        border-radius = 12;
        default-timeout = 5000;
        font = "JetBrainsMono Nerd Font 11";
        width = 350;
        height = 150;
        margin = "16";
        padding = "12";
      };
    };

    home.packages = with pkgs; [
      kitty
      pavucontrol
      networkmanagerapplet
    ];

    programs.kitty = {
      enable = true;
      settings = {
        font_family = "JetBrainsMono Nerd Font";
        font_size = 14;

        background = "#2e3440";
        foreground = "#d8dee9";
        cursor = "#8fbcbb";
        cursor_text_color = "#2e3440";
        selection_background = "#434c5e";
        selection_foreground = "#d8dee9";

        active_tab_background = "#81a1c1";
        active_tab_foreground = "#2e3440";
        inactive_tab_background = "#3b4252";
        inactive_tab_foreground = "#4c566a";

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

        background_opacity = "0.80";
        dynamic_background_opacity = "yes";
        background_blur = 1;
        window_padding_width = 12;
        confirm_os_window_close = 0;

        enable_audio_bell = false;
        shell_integration = "enabled";
      };
      keybindings = {
        "shift+enter" = "send_text all \\x1b[13;2u";
      };
    };

    home.file.".config/swayosd/style.css".text = ''
      window {
        background: rgba(59, 66, 82, 0.95);
        border-radius: 20px;
        border: 2px solid rgba(129, 161, 193, 0.4);
        padding: 12px 20px;
      }

      #container {
        margin: 16px;
      }

      image {
        margin-right: 12px;
        color: #81a1c1;
      }

      progressbar {
        min-height: 8px;
        border-radius: 4px;
        background: #3b4252;
      }

      progressbar:disabled {
        background: #434c5e;
      }

      progressbar progress {
        min-height: 8px;
        border-radius: 4px;
        background: linear-gradient(90deg, #81a1c1, #8fbcbb);
      }

      label {
        color: #d8dee9;
        font-family: "Quicksand", sans-serif;
        font-weight: 600;
        font-size: 14px;
      }
    '';
  };
}
