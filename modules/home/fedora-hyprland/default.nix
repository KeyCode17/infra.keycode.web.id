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
        # Give systemd user services the Wayland env (plain Hyprland doesn't
        # reach graphical-session.target, so daemons must be started explicitly).
        "systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP"
        "hyprctl setcursor Bibata-Modern-Classic 32"
        "swaybg -c 2e3440"
        "systemctl --user restart eww.service"
        "mako"
        "systemctl --user start hypridle.service"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "systemctl --user restart cliphist-text.service cliphist-image.service"
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

        # GDM launches Hyprland with a bare PATH (/usr/bin only); prepend the
        # nix profile so keybinds/exec-once can find rofi, cliphist, wofi, btm…
        "PATH,/home/keycode/.nix-profile/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/bin:/sbin"
      ];

      debug = {
        disable_logs = true;
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
        "$mod, N, exec, $HOME/.local/bin/net-menu"

        "$mod SHIFT, Q, killactive"
        "$mod SHIFT, E, exit"
        "$mod, V, togglefloating"
        "$mod, F, fullscreen"
        "$mod SHIFT, F, fullscreen, 1"
        "$mod, T, layoutmsg, togglesplit"
        "$mod SHIFT, B, exec, eww open --toggle bar"

        # move the focused window
        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, down, movewindow, d"

        # resize the focused window (hold and tap)
        "$mod CONTROL, left, resizeactive, -60 0"
        "$mod CONTROL, right, resizeactive, 60 0"
        "$mod CONTROL, up, resizeactive, 0 -60"
        "$mod CONTROL, down, resizeactive, 0 60"

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

        ", Print, exec, $HOME/.local/bin/capture-ui"
        "SHIFT, Print, exec, grim -g \"$(slurp)\" - | wl-copy"

        "$mod, C, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"
        "$mod SHIFT, V, exec, $HOME/.local/bin/clip-menu"

        "$mod SHIFT, C, exec, hyprpicker -a"

        "$mod, X, exec, hyprlock"
        "$mod SHIFT, X, exec, caffeine"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bindel = [
        ", XF86AudioRaiseVolume, exec, $HOME/.local/bin/osd vol-up"
        ", XF86AudioLowerVolume, exec, $HOME/.local/bin/osd vol-down"
        ", XF86MonBrightnessUp, exec, $HOME/.local/bin/osd bright-up"
        ", XF86MonBrightnessDown, exec, $HOME/.local/bin/osd bright-down"
      ];

      bindl = [
        ", XF86AudioMute, exec, $HOME/.local/bin/osd vol-mute"
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

  # Run eww as a single managed instance so it can't spawn duplicate bars.
  # Started from exec-once (plain Hyprland doesn't reach graphical-session.target).
  systemd.user.services.eww = {
    Unit = {
      Description = "eww daemon + bar";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      # PATH so widget onclick handlers (pavucontrol, etc.) resolve nix tools.
      Environment = "PATH=%h/.nix-profile/bin:/usr/local/bin:/usr/bin:/bin";
      ExecStart = "${pkgs.eww}/bin/eww daemon --no-daemonize";
      ExecStartPost = "${pkgs.bash}/bin/bash -c 'sleep 1; ${pkgs.eww}/bin/eww open bar'";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Clipboard history watchers (absolute paths so they work regardless of PATH).
  systemd.user.services.cliphist-text = {
    Unit = {
      Description = "cliphist text watcher";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.cliphist-image = {
    Unit = {
      Description = "cliphist image watcher";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
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

  # Volume/brightness OSD: change the level, then show a mako popup with a
  # progress bar (the int:value hint). x-canonical-private-synchronous replaces
  # the previous popup instead of stacking. Reliable without swayosd.
  home.file.".local/bin/osd" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      sink="@DEFAULT_AUDIO_SINK@"
      sync="string:x-canonical-private-synchronous:osd"

      case "$1" in
        vol-up)      wpctl set-volume -l 1.0 "$sink" 5%+ ;;
        vol-down)    wpctl set-volume "$sink" 5%- ;;
        vol-mute)    wpctl set-mute "$sink" toggle ;;
        bright-up)   brightnessctl set 5%+ ;;
        bright-down) brightnessctl set 5%- ;;
      esac

      case "$1" in
        bright-*)
          b=$(brightnessctl -m | cut -d, -f4 | tr -d %)
          notify-send -u low -h "$sync" -h "int:value:''${b}" "Brightness  ''${b}%"
          ;;
        *)
          if wpctl get-volume "$sink" | grep -q MUTED; then
            notify-send -u low -h "$sync" -h "int:value:0" "Muted"
          else
            v=$(wpctl get-volume "$sink" | awk '{print int($2*100)}')
            notify-send -u low -h "$sync" -h "int:value:''${v}" "Volume  ''${v}%"
          fi
          ;;
      esac
    '';
  };

  # GNOME-style capture control (Print): freezes the screen, shows the eww
  # `capture` panel on top; capture-do performs the chosen action.
  home.file.".local/bin/capture-ui" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      export PATH="$HOME/.nix-profile/bin:$PATH"
      viddir="$HOME/Videos/Recordings"

      # If a recording is running, Print stops it.
      if pgrep -x wf-recorder >/dev/null; then
        pkill -INT -x wf-recorder
        if [ -f "$viddir/.rec-modules" ]; then
          for m in $(cat "$viddir/.rec-modules"); do pactl unload-module "$m" 2>/dev/null; done
          rm -f "$viddir/.rec-modules"
        fi
        notify-send "Recording stopped" "Saved in $viddir"
        exit 0
      fi

      rm -f /tmp/.cap-done /tmp/.cap-cancel
      cur=$(eww get cap_cursor 2>/dev/null)
      hc="--hide-cursor"; [ "$cur" = "on" ] && hc=""
      wayfreeze $hc >/dev/null 2>&1 &
      WF=$!
      trap 'kill "$WF" 2>/dev/null' EXIT
      sleep 0.18
      eww open capture
      # hold the freeze until capture-do signals done/cancel (60s safety cap)
      n=0
      while [ ! -f /tmp/.cap-done ] && [ ! -f /tmp/.cap-cancel ] && [ $n -lt 600 ]; do
        sleep 0.1; n=$((n+1))
      done
      sleep 0.05
    '';
  };

  home.file.".local/bin/capture-do" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      export PATH="$HOME/.nix-profile/bin:$PATH"
      shotdir="$HOME/Pictures/Screenshots"; mkdir -p "$shotdir"
      viddir="$HOME/Videos/Recordings";     mkdir -p "$viddir"

      eww close capture
      if [ "$1" = "cancel" ]; then touch /tmp/.cap-cancel; exit 0; fi

      area=$(eww get cap_area 2>/dev/null)
      mode=$(eww get cap_mode 2>/dev/null)
      sleep 0.12   # let the panel vanish before slurp/grim

      geo=""
      case "$area" in
        selection) geo=$(slurp 2>/dev/null); [ -z "$geo" ] && { touch /tmp/.cap-cancel; exit 0; } ;;
        window)    geo=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"') ;;
        screen)    geo="" ;;
      esac

      if [ "$mode" = "video" ]; then
        aud=$(eww get cap_audio 2>/dev/null)
        touch /tmp/.cap-done   # unfreeze; recording is live
        sleep 0.25
        args=(); [ -n "$geo" ] && args+=(-g "$geo")
        SINK=$(pactl get-default-sink 2>/dev/null); SRC=$(pactl get-default-source 2>/dev/null)
        case "$aud" in
          system) [ -n "$SINK" ] && args+=(--audio="$SINK.monitor") || args+=(--audio) ;;
          mic)    [ -n "$SRC" ]  && args+=(--audio="$SRC")          || args+=(--audio) ;;
          both)
            if [ -n "$SINK" ] && [ -n "$SRC" ]; then
              n=$(pactl load-module module-null-sink sink_name=rec_mix sink_properties=device.description=rec_mix)
              l1=$(pactl load-module module-loopback source="$SRC" sink=rec_mix latency_msec=20)
              l2=$(pactl load-module module-loopback source="$SINK.monitor" sink=rec_mix latency_msec=20)
              printf '%s %s %s\n' "$n" "$l1" "$l2" > "$viddir/.rec-modules"
              args+=(--audio=rec_mix.monitor)
            else args+=(--audio); fi ;;
        esac
        f="$viddir/rec-$(date +%Y%m%d-%H%M%S).mp4"
        notify-send "Recording started" "Press Print again to stop"
        setsid -f wf-recorder "''${args[@]}" -f "$f" >/dev/null 2>&1
      else
        f="$shotdir/shot-$(date +%Y%m%d-%H%M%S).png"
        if [ -n "$geo" ]; then grim -g "$geo" "$f"; else grim "$f"; fi
        touch /tmp/.cap-done
        [ -f "$f" ] && { wl-copy < "$f"; notify-send -i "$f" "Screenshot saved" "$f"; }
      fi
    '';
  };

  # Screenshot / screen-record chooser as a horizontal icon toolbar (Print).
  # Screenshot: region / window / screen. Record: pick area then audio
  # (none / system / mic / both). Icons via printf \u so no raw glyphs in file.
  home.file.".local/bin/screenshot" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      export PATH="$HOME/.nix-profile/bin:$PATH"
      shotdir="$HOME/Pictures/Screenshots"; mkdir -p "$shotdir"
      viddir="$HOME/Videos/Recordings";     mkdir -p "$viddir"
      RASI="$HOME/.config/rofi/capture.rasi"

      I_REGION=$(printf ''); I_WIN=$(printf ''); I_SCREEN=$(printf '')
      I_REC=$(printf '');    I_STOP=$(printf ''); I_BACK=$(printf '')
      I_MUTE=$(printf '');   I_SYS=$(printf '');  I_MIC=$(printf '')
      I_BOTH=$(printf '')

      pick() { rofi -dmenu -i -p "$1" -theme "$RASI" -mesg "$2"; }

      CURFILE="$HOME/.cache/screenshot-cursor"
      [ -f "$CURFILE" ] || echo off > "$CURFILE"
      cursor=$(cat "$CURFILE")

      # Freeze the WHOLE screen the instant Print is pressed. The menu and slurp
      # then run on top of the frozen image; grim captures the freeze. The trap
      # guarantees we always unfreeze, even on cancel/error.
      hc=""; [ "$cursor" = off ] && hc="--hide-cursor"
      wayfreeze $hc >/dev/null 2>&1 &
      WF=$!
      unfreeze() { [ -n "$WF" ] && kill "$WF" 2>/dev/null; WF=""; }
      trap unfreeze EXIT
      sleep 0.18

      save_shot() { wl-copy < "$1"; notify-send -i "$1" "Screenshot saved" "$1"; }
      # menu sits on the frozen screen; make sure it's gone before grim
      wait_ui_gone() { while pgrep -x rofi >/dev/null 2>&1; do sleep 0.03; done; sleep 0.08; }

      shot_save() {  # $1 = "" full | geo ; capture the frozen screen
        wait_ui_gone
        f="$shotdir/shot-$(date +%Y%m%d-%H%M%S).png"
        if [ -n "$1" ]; then grim -g "$1" "$f"; else grim "$f"; fi
        unfreeze
        [ -f "$f" ] && save_shot "$f"
      }

      stop_rec() {
        pkill -INT -x wf-recorder
        if [ -f "$viddir/.rec-modules" ]; then
          for m in $(cat "$viddir/.rec-modules"); do pactl unload-module "$m" 2>/dev/null; done
          rm -f "$viddir/.rec-modules"
        fi
        notify-send "Recording stopped" "Saved in $viddir"
      }

      ask_audio() {
        a=$(printf '%s' "$I_MUTE  No audio
$I_SYS  System
$I_MIC  Mic
$I_BOTH  System + Mic" | pick "Audio" "Pick audio source")
        case "$a" in
          *"No audio") echo none ;; *System) echo system ;;
          *Mic) echo mic ;; *"System + Mic") echo both ;; *) echo "" ;;
        esac
      }

      start_rec() {  # $1 = geo ("" full)   $2 = audio
        args=(); SINK=$(pactl get-default-sink 2>/dev/null); SRC=$(pactl get-default-source 2>/dev/null)
        [ -n "$1" ] && args+=(-g "$1")
        case "$2" in
          system) [ -n "$SINK" ] && args+=(--audio="$SINK.monitor") || args+=(--audio) ;;
          mic)    [ -n "$SRC" ]  && args+=(--audio="$SRC")          || args+=(--audio) ;;
          both)
            if [ -n "$SINK" ] && [ -n "$SRC" ]; then
              n=$(pactl load-module module-null-sink sink_name=rec_mix sink_properties=device.description=rec_mix)
              l1=$(pactl load-module module-loopback source="$SRC" sink=rec_mix latency_msec=20)
              l2=$(pactl load-module module-loopback source="$SINK.monitor" sink=rec_mix latency_msec=20)
              printf '%s %s %s\n' "$n" "$l1" "$l2" > "$viddir/.rec-modules"
              args+=(--audio=rec_mix.monitor)
            else args+=(--audio); fi ;;
        esac
        f="$viddir/rec-$(date +%Y%m%d-%H%M%S).mp4"
        notify-send "Recording started" "Press Print -> Stop recording"
        setsid -f wf-recorder "''${args[@]}" -f "$f" >/dev/null 2>&1
      }

      CURUP=$(printf '%s' "$cursor" | tr a-z A-Z)
      top=""
      pgrep -x wf-recorder >/dev/null && top="$I_STOP  Stop recording
"
      main="''${top}[ Pointer: $CURUP ]
$I_REGION  Shot region
$I_WIN  Shot window
$I_SCREEN  Shot screen
$I_REC  Rec region
$I_REC  Rec screen"

      c=$(printf '%s' "$main" | pick "Capture" "Screen frozen - pick what to capture")
      case "$c" in
        *"Stop recording") unfreeze; stop_rec ;;
        *"Pointer:"*)
          [ "$cursor" = on ] && echo off > "$CURFILE" || echo on > "$CURFILE"
          unfreeze; trap - EXIT; exec "$0" ;;
        *"Shot region")
          wait_ui_gone; g=$(slurp 2>/dev/null)
          [ -z "$g" ] && exit 0
          shot_save "$g" ;;
        *"Shot window")
          g=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
          shot_save "$g" ;;
        *"Shot screen") shot_save "" ;;
        *"Rec region")
          wait_ui_gone; g=$(slurp 2>/dev/null); unfreeze
          [ -z "$g" ] && exit 0
          aud=$(ask_audio); [ -z "$aud" ] && exit 0
          start_rec "$g" "$aud" ;;
        *"Rec screen")
          unfreeze
          aud=$(ask_audio); [ -z "$aud" ] && exit 0
          start_rec "" "$aud" ;;
        *) exit 0 ;;
      esac
    '';
  };

  home.file.".config/rofi/capture.rasi".text = ''
    * {
      font:   "CaskaydiaCove Nerd Font 11";
      bg:     #2e3440;
      bg-alt: #3b4252;
      fg:     #d8dee9;
      accent: #81a1c1;
      muted:  #4c566a;
      background-color: transparent;
      text-color: @fg;
    }
    configuration { show-icons: false; }
    window {
      transparency: "real";
      background-color: @bg;
      border: 2px;
      border-color: @accent;
      border-radius: 22px;
      width: 540px;
      location: center;
    }
    mainbox { padding: 24px; spacing: 18px; children: [ message, listview ]; }
    message { border: 0; padding: 0; }
    textbox {
      text-color: @accent;
      horizontal-align: 0.5;
      font: "CaskaydiaCove Nerd Font Bold 14";
    }
    listview { columns: 3; lines: 2; spacing: 14px; fixed-height: false; }
    element {
      padding: 22px 14px;
      border-radius: 16px;
      background-color: @bg-alt;
      text-color: @fg;
    }
    element selected {
      background-color: @accent;
      text-color: @bg;
    }
    element-text { horizontal-align: 0.5; vertical-align: 0.5; }
  '';

  # Clipboard manager: cliphist history + pin/star support via rofi.
  # Alt+P pins the highlighted entry, Alt+X unpins. Enter copies it.
  home.file.".local/bin/clip-menu" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      export PATH="$HOME/.nix-profile/bin:$PATH"
      PINS="''${XDG_DATA_HOME:-$HOME/.local/share}/cliphist-pins"
      mkdir -p "$(dirname "$PINS")"; touch "$PINS"
      TAB=$'\t'

      prev() { base64 -d 2>/dev/null | tr '\n\t' '  ' | sed 's/^ *//' | cut -c1-72; }

      while true; do
        KIND=(); DATA=(); DISP=()
        # pinned entries first
        while IFS= read -r b64; do
          [ -n "$b64" ] || continue
          KIND+=("pin"); DATA+=("$b64")
          DISP+=("★  $(printf '%s' "$b64" | prev)")
        done < "$PINS"
        # cliphist history (strip the leading "id<tab>" for display)
        while IFS= read -r line; do
          [ -n "$line" ] || continue
          KIND+=("hist"); DATA+=("$line")
          DISP+=("    ''${line#*$TAB}")
        done < <(cliphist list 2>/dev/null)

        [ ''${#DISP[@]} -eq 0 ] && { notify-send -u low "Clipboard" "History is empty"; exit 0; }

        idx=$(printf '%s\n' "''${DISP[@]}" | rofi -dmenu -i -format i \
              -p "Clipboard" -theme "$HOME/.config/rofi/clip.rasi" \
              -mesg "Alt+P pin     Alt+X unpin     Enter copy" \
              -kb-custom-1 "Alt+p" -kb-custom-2 "Alt+x")
        rc=$?
        [ -z "$idx" ] && exit 0
        kind="''${KIND[$idx]}"; data="''${DATA[$idx]}"

        case $rc in
          0)
            if [ "$kind" = pin ]; then printf '%s' "$data" | base64 -d | wl-copy
            else printf '%s' "$data" | cliphist decode | wl-copy; fi
            exit 0 ;;
          10)  # Alt+P: pin a history item
            if [ "$kind" = hist ]; then
              raw=$(printf '%s' "$data" | cliphist decode | base64 -w0)
              grep -qxF "$raw" "$PINS" || printf '%s\n' "$raw" >> "$PINS"
            fi ;;
          11)  # Alt+X: unpin a pinned item
            if [ "$kind" = pin ]; then
              grep -vxF "$data" "$PINS" > "$PINS.tmp" && mv "$PINS.tmp" "$PINS"
            fi ;;
          *) exit 0 ;;
        esac
      done
    '';
  };

  home.file.".config/rofi/clip.rasi".text = ''
    * {
      font:   "CaskaydiaCove Nerd Font 11";
      bg:     #2e3440;
      bg-alt: #3b4252;
      fg:     #d8dee9;
      accent: #81a1c1;
      muted:  #4c566a;
      background-color: transparent;
      text-color: @fg;
    }
    configuration { show-icons: false; }
    window {
      transparency: "real";
      background-color: @bg;
      border: 2px;
      border-color: @accent;
      border-radius: 16px;
      width: 600px;
    }
    mainbox { padding: 14px; spacing: 10px; }
    inputbar {
      background-color: @bg-alt;
      border-radius: 12px;
      padding: 12px 14px;
      spacing: 8px;
      children: [ prompt, entry ];
    }
    prompt { text-color: @accent; }
    entry  { placeholder: "Search…"; placeholder-color: @muted; }
    message { border: 0; padding: 0; }
    textbox { text-color: @muted; padding: 2px 6px; }
    listview { lines: 12; scrollbar: false; spacing: 3px; }
    element { padding: 9px 12px; border-radius: 10px; }
    element selected { background-color: @accent; text-color: @bg; }
    element-text { text-color: inherit; vertical-align: 0.5; }
  '';

  # Simple network menu (rofi): wifi list + ethernet, connect/disconnect,
  # password prompt, wifi on/off toggle. Opened by clicking the bar's net widget.
  home.file.".local/bin/net-menu" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      export PATH="$HOME/.nix-profile/bin:$PATH"
      RASI="$HOME/.config/rofi/clip.rasi"
      I_WIFI=$(printf ''); I_LOCK=$(printf ''); I_CHK=$(printf '')
      I_PWR=$(printf '');  I_DIS=$(printf ''); I_LAN=$(printf '')
      I_REF=$(printf '')

      KIND=(); DATA=(); DISP=()
      add() { KIND+=("$1"); DATA+=("$2"); DISP+=("$3"); }

      wifi=$(nmcli radio wifi 2>/dev/null)
      if [ "$wifi" = enabled ]; then
        add toggle off "$I_PWR  Turn Wi-Fi Off"
        add rescan "" "$I_REF  Rescan networks"
        nmcli dev wifi rescan >/dev/null 2>&1
        while IFS=: read -r inuse ssid signal sec; do
          [ -z "$ssid" ] && continue
          mark=""; [ "$inuse" = "*" ] && mark="$I_CHK "
          lk="";   [ -n "$sec" ] && lk="  $I_LOCK"
          add wifi "$ssid" "$I_WIFI  $mark$ssid  ($signal%)$lk"
        done < <(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null \
                 | awk -F: 'NF>=2 && $2!="" && !seen[$2]++' | sort -t: -k3 -rn)
      else
        add toggle on "$I_PWR  Turn Wi-Fi On"
      fi

      awifi=$(nmcli -t -f NAME,TYPE con show --active 2>/dev/null | awk -F: '$2 ~ /wireless/{print $1; exit}')
      [ -n "$awifi" ] && add disconnect "$awifi" "$I_DIS  Disconnect $awifi"

      eth=$(nmcli -t -f DEVICE,TYPE,STATE device 2>/dev/null | awk -F: '$2=="ethernet"{print $3; exit}')
      [ -n "$eth" ] && add eth "" "$I_LAN  Ethernet: $eth"

      idx=$(printf '%s\n' "''${DISP[@]}" | rofi -dmenu -i -format i -p "Network" \
            -theme "$RASI" -mesg "Click a network to connect")
      [ -z "$idx" ] && exit 0
      k="''${KIND[$idx]}"; d="''${DATA[$idx]}"

      note() { notify-send -u low "Network" "$1"; }

      case "$k" in
        toggle) nmcli radio wifi "$d"; sleep 1; exec "$0" ;;
        rescan) nmcli dev wifi rescan >/dev/null 2>&1; sleep 2; exec "$0" ;;
        disconnect) nmcli con down id "$d" && note "Disconnected $d" ;;
        eth) nm-connection-editor ;;
        wifi)
          if nmcli -t -f NAME con show 2>/dev/null | grep -qxF "$d"; then
            nmcli con up id "$d" && note "Connected to $d" || note "Failed to connect $d"
          else
            sec=$(nmcli -t -f SSID,SECURITY dev wifi list 2>/dev/null | awk -F: -v s="$d" '$1==s{print $2; exit}')
            if [ -n "$sec" ]; then
              pw=$(rofi -dmenu -password -p "Password" -theme "$RASI" \
                   -mesg "Wi-Fi password for $d" < /dev/null)
              [ -z "$pw" ] && exit 0
              nmcli dev wifi connect "$d" password "$pw" \
                && note "Connected to $d" || note "Could not connect (wrong password?)"
            else
              nmcli dev wifi connect "$d" && note "Connected to $d" || note "Failed to connect $d"
            fi
          fi ;;
      esac
    '';
  };

  gtk = {
    enable = true;

    theme = {
      name = "Nordic";
      package = pkgs.nordic;
    };

    iconTheme = {
      name = "Nordzy";
      package = pkgs.nordzy-icon-theme;
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

  # GTK4 / libadwaita apps (nautilus, etc.) ignore the gtk-theme setting, so
  # link the Nordic theme's GTK4 CSS into ~/.config/gtk-4.0 to actually skin them.
  xdg.configFile."gtk-4.0/gtk.css".source =
    "${pkgs.nordic}/share/themes/Nordic/gtk-4.0/gtk.css";
  xdg.configFile."gtk-4.0/gtk-dark.css".source =
    "${pkgs.nordic}/share/themes/Nordic/gtk-4.0/gtk-dark.css";

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
      gtk-theme = "Nordic";
      icon-theme = "Nordzy";
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
    rofi
    grim
    slurp
    wf-recorder
    wayfreeze
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
