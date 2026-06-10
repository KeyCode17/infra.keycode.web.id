{ pkgs, ... }:
# Flat, standalone-home-manager Hyprland config for Fedora.
# The Hyprland BINARY comes from Fedora (dnf/COPR solopasha/hyprland) so it uses
# the system GPU drivers. home-manager only manages the config:
#   wayland.windowManager.hyprland.package      = null;
#   wayland.windowManager.hyprland.portalPackage = null;
# hyprlock is also native (GL) — the keybind just calls `hyprlock` on PATH.
let
  caffeine = pkgs.writeShellScriptBin "caffeine" ''
    if ${pkgs.systemd}/bin/systemctl --user -q is-active hypridle; then
      ${pkgs.systemd}/bin/systemctl --user stop hypridle
      ${pkgs.libnotify}/bin/notify-send -t 2000 -u low \
        "☕ Caffeine ON" "Idle lock & sleep disabled"
    else
      ${pkgs.systemd}/bin/systemctl --user start hypridle
      ${pkgs.libnotify}/bin/notify-send -t 2000 -u low \
        "Caffeine OFF" "Normal idle lock & sleep restored"
    fi
  '';
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    xwayland.enable = true;

    settings = {
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

      monitor = [
        "eDP-1,1920x1080@60,0x0,1.0"
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

      cursor = {
        default_monitor = "";
        no_hardware_cursors = true; # NVIDIA: avoids invisible/garbled cursor
      };

      env = [
        "XCURSOR_THEME,Bibata-Modern-Classic"
        "XCURSOR_SIZE,32"
        "NIXOS_OZONE_WL,1"
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
        "MOZ_ENABLE_WAYLAND,1"

        # Hybrid Intel + NVIDIA (Optimus). Intel iGPU = /dev/dri/card1 drives the
        # eDP-1 panel; make it the primary scanout device so Hyprland starts,
        # with the NVIDIA card available as secondary.
        "AQ_DRM_DEVICES,/dev/dri/card1:/dev/dri/card0"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "LIBVA_DRIVER_NAME,nvidia"
        "NVD_BACKEND,direct"
      ];

      debug = {
        disable_logs = false;
      };

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };

      # Hyprland 0.51 (Fedora COPR) syntax: windowrulev2 with class:/title:
      windowrulev2 = [
        "float, class:^(pavucontrol)$"
        "float, class:^(nm-connection-editor)$"
        "float, class:^(org.gnome.Calculator)$"
        "float, title:^(Picture-in-Picture)$"
        "opacity 1.0 0.92, class:^(kitty)$"
        "opacity 1.0 0.92, class:^(Alacritty)$"
        "opacity 0.9, class:^(code)$"
      ];

      layerrule = [
        "blur, gtk-layer-shell"
        "ignorealpha 0.3, gtk-layer-shell"
        "blur, wofi"
        "ignorealpha 0.3, wofi"
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
        "$mod, J, layoutmsg, togglesplit"
        "$mod SHIFT, B, exec, eww open --toggle bar"
        "$mod SHIFT, H, exec, systemctl hibernate"

        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"

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
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];

      bindl = [
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ", switch:on:Lid Switch, exec, systemctl suspend"
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
      color = rgba(46, 52, 64, 1.0)
      blur_passes = 0
    }

    label {
      monitor =
      text = cmd[update:1000] echo "$(date +'%H:%M')"
      color = rgba(216, 222, 233, 0.95)
      font_size = 120
      font_family = CaskaydiaCove Nerd Font ExtraBold
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
      font_family = CaskaydiaCove Nerd Font Medium
      position = 0, 120
      halign = center
      valign = center
    }

    label {
      monitor =
      text = $USER
      color = rgba(216, 222, 233, 0.95)
      font_size = 16
      font_family = CaskaydiaCove Nerd Font Bold
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
      placeholder_text = <span font_family="CaskaydiaCove Nerd Font" foreground="##81a1c1cc">  Enter password</span>
      hide_input = false
      position = 0, -200
      halign = center
      valign = center
      shadow_passes = 2
      shadow_size = 4
      shadow_color = rgba(0, 0, 0, 0.35)
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
      font = "CaskaydiaCove Nerd Font 11";
      width = 350;
      height = 150;
      margin = "16";
      padding = "12";
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        # On resume: turn the screen back on and make sure the eww bar is up
        # (it can get killed across a suspend/resume cycle on NVIDIA).
        after_sleep_cmd = "hyprctl dispatch dpms on; eww open bar";
        ignore_dbus_inhibit = false;
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          # Screen off on idle, back on with the bar when you return.
          timeout = 420;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on; eww open bar";
        }
        # No idle auto-suspend (removed). Closing the lid still suspends.
      ];
    };
  };

  programs.eww = {
    enable = true;
    configDir = ./eww;
  };

  programs.wofi = {
    enable = true;

    settings = {
      width = 600;
      height = 360;
      location = "center";
      show = "drun";
      prompt = "Search";
      filter_rate = 100;
      allow_markup = true;
      no_actions = true;
      halign = "fill";
      orientation = "vertical";
      content_halign = "fill";
      insensitive = true;
      allow_images = true;
      image_size = 40;
      gtk_dark = true;
      dynamic_lines = true;
      columns = 1;
      hide_scroll = true;
      matching = "fuzzy";
      sort_order = "alphabetical";
    };

    style = ''
      * {
        font-family: "CaskaydiaCove Nerd Font", sans-serif;
        font-size: 15px;
      }

      window {
        background: #2e3440;
        border: 1px solid rgba(129, 161, 193, 0.3);
        border-radius: 16px;
      }

      #outer-box {
        margin: 0;
        padding: 0;
      }

      #input {
        background: transparent;
        border: none;
        border-bottom: 1px solid rgba(67, 76, 94, 0.6);
        border-radius: 0;
        padding: 20px 24px;
        color: #d8dee9;
        font-size: 22px;
        font-weight: 300;
        margin: 0;
      }

      #input:focus {
        border-bottom: 1px solid #81a1c1;
        box-shadow: none;
        outline: none;
      }

      #input image {
        color: #81a1c1;
        margin-right: 12px;
      }

      #input:first-child > :first-child {
        min-height: 28px;
        min-width: 28px;
      }

      #scroll {
        background: transparent;
        margin: 0;
        padding: 8px 0;
      }

      #inner-box {
        background: transparent;
        padding: 0 8px;
      }

      #entry {
        padding: 12px 16px;
        margin: 2px 8px;
        border-radius: 10px;
        background: transparent;
        transition: all 0.15s ease;
      }

      #entry:hover {
        background: rgba(129, 161, 193, 0.15);
      }

      #entry:selected {
        background: linear-gradient(135deg, #81a1c1, #8fbcbb);
        box-shadow: 0 2px 8px rgba(129, 161, 193, 0.3);
      }

      #entry:selected #text {
        color: #2e3440;
        font-weight: 500;
      }

      #text {
        color: #d8dee9;
        margin-left: 12px;
      }

      #text:selected {
        color: #2e3440;
      }

      #img {
        margin-right: 4px;
        border-radius: 8px;
      }
    '';
  };

  home.file.".local/bin/wofi-power" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash

      entries=" Lock\n Logout\n Suspend\n Reboot\n Shutdown"

      selected=$(echo -e $entries | wofi --dmenu --prompt "Power Menu" --width 250 --height 280 --cache-file /dev/null)

      case $selected in
        " Lock")
          hyprlock;;
        " Logout")
          hyprctl dispatch exit;;
        " Suspend")
          systemctl suspend;;
        " Reboot")
          systemctl reboot;;
        " Shutdown")
          systemctl poweroff;;
      esac
    '';
  };

  gtk = {
    enable = true;

    theme = {
      name = "rose-pine";
      package = pkgs.rose-pine-gtk-theme;
    };

    iconTheme = {
      name = "rose-pine";
      package = pkgs.rose-pine-icon-theme;
    };

    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 32;
    };

    font = {
      name = "CaskaydiaCove Nerd Font";
      size = 11;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-decoration-layout = "appmenu:none";
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-decoration-layout = "appmenu:none";
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style = {
      name = "kvantum";
    };
  };

  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=rose-pine-iris
  '';

  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 32;
    gtk.enable = true;
    x11.enable = true;
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "rose-pine";
      icon-theme = "rose-pine";
      cursor-theme = "Bibata-Modern-Classic";
      font-name = "CaskaydiaCove Nerd Font 11";
      document-font-name = "CaskaydiaCove Nerd Font 11";
      monospace-font-name = "CaskaydiaCove Nerd Font 11";
    };
  };

  # Kitty is installed natively (dnf) for proper GPU drivers. home-manager only
  # writes its config here so we don't shadow the native binary with a nix build.
  xdg.configFile."kitty/kitty.conf".text = ''
    font_family CaskaydiaCove Nerd Font
    font_size 14

    background #2e3440
    foreground #d8dee9
    cursor #8fbcbb
    cursor_text_color #2e3440
    selection_background #434c5e
    selection_foreground #d8dee9

    active_tab_background #81a1c1
    active_tab_foreground #2e3440
    inactive_tab_background #3b4252
    inactive_tab_foreground #4c566a

    color0 #3b4252
    color1 #bf616a
    color2 #5e81ac
    color3 #ebcb8b
    color4 #88c0d0
    color5 #81a1c1
    color6 #8fbcbb
    color7 #d8dee9

    color8 #4c566a
    color9 #bf616a
    color10 #5e81ac
    color11 #ebcb8b
    color12 #88c0d0
    color13 #81a1c1
    color14 #8fbcbb
    color15 #d8dee9

    background_opacity 0.92
    dynamic_background_opacity yes
    background_blur 1
    window_padding_width 12
    confirm_os_window_close 0

    enable_audio_bell no
    shell_integration enabled

    map shift+enter send_text all \x1b[13;2u
  '';

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
      font-family: "CaskaydiaCove Nerd Font", sans-serif;
      font-weight: 600;
      font-size: 14px;
    }
  '';

  # Native (dnf) provides the GL / duplicate tools: kitty, wofi, grim, slurp,
  # hyprpicker, brightnessctl, playerctl, hyprlock. We only pull from nix the
  # GTK/daemon bits Fedora did NOT install, so nothing GL-heavy comes from nix.
  home.packages = with pkgs; [
    caffeine

    swaybg
    swayosd
    cliphist
    wl-clipboard
    libnotify
    jq
    socat
    wireplumber
    polkit_gnome

    pavucontrol
    networkmanagerapplet

    # qt/gtk theming
    libsForQt5.qtstyleplugin-kvantum
    kdePackages.qtstyleplugin-kvantum
    rose-pine-kvantum
    adw-gtk3
  ];
}
