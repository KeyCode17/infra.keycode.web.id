{
  pkgs,
  lib,
  username,
  enableTilingWM,
  ...
}:
let
  # Workspace indicator — responds to aerospace_workspace_change event.
  # $NAME  is set by sketchybar (e.g. "space.3")
  # $AEROSPACE_FOCUSED_WORKSPACE is passed via the trigger payload
  spaceScript = pkgs.writeShellScript "sb-space" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    WS_NUM="''${NAME#space.}"
    if [ "$AEROSPACE_FOCUSED_WORKSPACE" = "$WS_NUM" ]; then
      sketchybar --animate overshoot 15 --set "$NAME" \
        background.color=0xff81a1c1 \
        background.height=12 \
        background.corner_radius=6 \
        icon.padding_left=10 \
        icon.padding_right=10
    else
      sketchybar --animate overshoot 15 --set "$NAME" \
        background.color=0x30d8dee9 \
        background.height=8 \
        background.corner_radius=4 \
        icon.padding_left=1 \
        icon.padding_right=1
    fi
  '';

  clockHScript = pkgs.writeShellScript "sb-clock-h" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    sketchybar --set clock_h label="$(date +'%I')"
  '';
  clockPScript = pkgs.writeShellScript "sb-clock-p" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    sketchybar --set clock_p label="$(date +'%p')"
  '';
  clockMScript = pkgs.writeShellScript "sb-clock-m" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    sketchybar --set clock_m label="$(date +'%M')"
  '';
  clockDateScript = pkgs.writeShellScript "sb-clock-date" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    sketchybar --set clock_date label="$(date +'%d')"
  '';
  clockMonthScript = pkgs.writeShellScript "sb-clock-month" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    sketchybar --set clock_month label="$(date +'%b')"
  '';

  # Caffeine indicator — coffee icon shown only while caffeine mode is ON.
  # Reads pmset's SleepDisabled, the same state of record the toggle in
  # modules/darwin/aerospace/default.nix writes; a pidfile check would drift
  # from it whenever caffeinate dies or its PID gets reused.
  # Refreshed instantly by the toggle via `--trigger caffeine_change`.
  caffeineScript = pkgs.writeShellScript "sb-caffeine" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    if /usr/bin/pmset -g | grep -qE 'SleepDisabled[[:space:]]+1'; then
      sketchybar --set caffeine drawing=on
    else
      sketchybar --set caffeine drawing=off
    fi
  '';

  # Alt+Shift+B (bound in AeroSpace) hides the whole bar AND drops the top gap to 0
  # so windows reclaim that space and go full-height; pressing again restores both.
  # Needs ~/.aerospace.toml to be a writable file (see the aerospace module).
  # Exposed at ~/.local/bin/sketchybar-bar-toggle.
  barToggleScript = pkgs.writeShellScript "sb-bar-toggle" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    STATE="/tmp/.sketchybar-barhidden"
    CFG="$HOME/.aerospace.toml"
    AS="/run/current-system/sw/bin/aerospace"
    set_gap() {
      sed -E "s/^[[:space:]]*outer\.top[[:space:]]*=.*/    outer.top       = $1/" "$CFG" > "$CFG.tmp" && mv "$CFG.tmp" "$CFG"
    }
    if [ -f "$STATE" ]; then
      # currently hidden -> SHOW bar + restore the 20px top gap
      rm -f "$STATE"
      sketchybar --bar hidden=off
      set_gap 20
    else
      # currently shown -> HIDE bar + remove top gap (windows go full to the top)
      touch "$STATE"
      sketchybar --bar hidden=on
      set_gap 0
    fi
    sleep 0.2
    "$AS" reload-config
  '';

  wifiScript = pkgs.writeShellScript "sb-wifi" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    # Interface actually carrying the default route (internet)
    IFACE=$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')
    # Which device is the Wi-Fi card
    WIFI_DEV=$(networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi/{getline; print $2; exit}')

    if [ -z "$IFACE" ]; then
      # not connected
      sketchybar --set wifi icon="󰤮" icon.color=0x884c566a label="off"
    elif [ "$IFACE" = "$WIFI_DEV" ]; then
      # on Wi-Fi -> show network name (SSID), not the IP
      SSID=$(networksetup -getairportnetwork "$WIFI_DEV" 2>/dev/null | sed -n 's/^Current Wi-Fi Network: //p' | cut -c1-14)
      [ -z "$SSID" ] && SSID="Wi-Fi"
      sketchybar --set wifi icon="󰖩" icon.color=0xff88c0d0 label="$SSID"
    else
      # on wired Ethernet
      sketchybar --set wifi icon="󰈀" icon.color=0xff88c0d0 label="LAN"
    fi
  '';

  volumeScript = pkgs.writeShellScript "sb-volume" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    VOL=$(osascript -e "output volume of (get volume settings)" 2>/dev/null)
    MUTED=$(osascript -e "output muted of (get volume settings)" 2>/dev/null)
    if [ "$MUTED" = "true" ]; then
      sketchybar --set volume icon="󰖁" icon.color=0x884c566a label="—"
    else
      sketchybar --set volume icon="󰕾" icon.color=0xff88c0d0 label="''${VOL}"
    fi
  '';

  brightnessScript = pkgs.writeShellScript "sb-brightness" ''
        export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
        BRIGHT=$(python3 -c "
    import ctypes
    ds = ctypes.CDLL('/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices')
    ds.DisplayServicesGetBrightness.restype = ctypes.c_int
    val = ctypes.c_float()
    ds.DisplayServicesGetBrightness(1, ctypes.byref(val))
    print(int(val.value * 100))
    " 2>/dev/null)
        [ -z "$BRIGHT" ] && BRIGHT="—"
        sketchybar --set brightness icon="󰖨" icon.color=0xffebcb8b label="''${BRIGHT}"
  '';

  batteryScript = pkgs.writeShellScript "sb-battery" ''
    export PATH="/usr/local/bin:/run/current-system/sw/bin:$PATH"
    BATT=$(pmset -g batt 2>/dev/null | grep -o "[0-9]*%" | head -1 | tr -d "%")
    AC=$(pmset -g batt 2>/dev/null | grep -c "AC Power" || true)
    if [ "$AC" -gt 0 ]; then
      sketchybar --set battery icon="󱐋" icon.color=0xff88c0d0 label="''${BATT}"
    elif [ "''${BATT:-100}" -le 15 ]; then
      sketchybar --set battery icon="󱐋" icon.color=0xffbf616a label="''${BATT}"
    else
      sketchybar --set battery icon="󱐋" icon.color=0xffebcb8b label="''${BATT}"
    fi
  '';

  sketchybarrc = pkgs.writeShellScript "sketchybarrc" ''
    # Nord — sketchybar top bar (mirrors eww vertical bar)

    sketchybar --bar \
      position=top \
      height=40 \
      blur_radius=20 \
      color=0xdd2e3440 \
      border_width=1 \
      border_color=0x3081a1c1 \
      corner_radius=16 \
      margin=12 \
      y_offset=8 \
      topmost=window

    sketchybar --default \
      updates=when_shown \
      icon.font="CaskaydiaCove Nerd Font Mono:Regular:16.0" \
      icon.color=0xff81a1c1 \
      icon.padding_left=4 \
      icon.padding_right=4 \
      label.font="CaskaydiaCove Nerd Font:SemiBold:13.0" \
      label.color=0xffd8dee9 \
      label.padding_left=4 \
      label.padding_right=4

    # Nix logo
    sketchybar --add item logo left \
      --set logo \
        icon="" \
        icon.color=0xff81a1c1 \
        icon.font="CaskaydiaCove Nerd Font Mono:Regular:22.0" \
        icon.padding_left=16 \
        icon.padding_right=12 \
        label.drawing=off

    # Register Aerospace workspace change event
    sketchybar --add event aerospace_workspace_change

    # Workspaces 1–6 (matches eww)
    for i in 1 2 3 4 5 6; do
      sketchybar --add item "space.''${i}" left \
        --set "space.''${i}" \
          script="${spaceScript}" \
          click_script="aerospace workspace ''${i}" \
          icon.drawing=off \
          label.drawing=off \
          background.color=0x30d8dee9 \
          background.corner_radius=4 \
          background.height=8 \
          icon=" " \
          icon.font="CaskaydiaCove Nerd Font:Regular:1.0" \
          icon.drawing=on \
          icon.padding_left=1 \
          icon.padding_right=1 \
          icon.color=0x00000000 \
          label.drawing=off \
          padding_left=6 \
          padding_right=6 \
        --subscribe "space.''${i}" aerospace_workspace_change
    done

    # Caffeine mode indicator (hidden unless active). Click also toggles.
    sketchybar --add event caffeine_change
    sketchybar --add item caffeine right \
      --set caffeine \
        script="${caffeineScript}" \
        updates=on \
        drawing=off \
        icon="$(printf '\363\260\205\266')" \
        icon.color=0xffebcb8b \
        icon.font="CaskaydiaCove Nerd Font Mono:Regular:16.0" \
        icon.padding_left=10 \
        icon.padding_right=10 \
        label.drawing=off \
        click_script="/Users/karyudi/.local/bin/caffeine-toggle" \
      --subscribe caffeine caffeine_change

    # Status items — consistent icon+label spacing
    sketchybar --add item wifi right \
      --set wifi \
        update_freq=10 \
        script="${wifiScript}" \
        icon="󰖩" \
        icon.color=0xff88c0d0 \
        icon.padding_left=10 \
        icon.padding_right=4 \
        label="..." \
        label.padding_left=0 \
        label.padding_right=10

    sketchybar --add item volume right \
      --set volume \
        update_freq=3 \
        script="${volumeScript}" \
        icon="󰕾" \
        icon.color=0xff88c0d0 \
        icon.padding_left=10 \
        icon.padding_right=4 \
        label="..." \
        label.padding_left=0 \
        label.padding_right=10

    sketchybar --add item brightness right \
      --set brightness \
        update_freq=5 \
        script="${brightnessScript}" \
        icon="󰖨" \
        icon.color=0xffebcb8b \
        icon.padding_left=10 \
        icon.padding_right=4 \
        label="..." \
        label.padding_left=0 \
        label.padding_right=10

    sketchybar --add item battery right \
      --set battery \
        update_freq=30 \
        script="${batteryScript}" \
        icon="󱐋" \
        icon.color=0xffebcb8b \
        icon.padding_left=10 \
        icon.padding_right=4 \
        label="..." \
        label.padding_left=0 \
        label.padding_right=10

    # Clock — H · M   date Mon
    sketchybar --add item clock_month right \
      --set clock_month \
        update_freq=1800 \
        script="${clockMonthScript}" \
        icon.drawing=off \
        label.font="CaskaydiaCove Nerd Font:Bold:13.0" \
        label.color=0xffd8dee9 \
        label.padding_left=2 \
        label.padding_right=18

    sketchybar --add item clock_date right \
      --set clock_date \
        update_freq=1800 \
        script="${clockDateScript}" \
        icon.drawing=off \
        label.font="CaskaydiaCove Nerd Font:Bold:16.0" \
        label.color=0xffd8dee9 \
        label.padding_left=10 \
        label.padding_right=2

    sketchybar --add item clock_p right \
      --set clock_p \
        update_freq=5 \
        script="${clockPScript}" \
        icon.drawing=off \
        label.font="CaskaydiaCove Nerd Font:Bold:11.0" \
        label.color=0xff88c0d0 \
        label.padding_left=3 \
        label.padding_right=2

    sketchybar --add item clock_m right \
      --set clock_m \
        update_freq=5 \
        script="${clockMScript}" \
        icon.drawing=off \
        label.font="CaskaydiaCove Nerd Font:Bold:18.0" \
        label.color=0xff81a1c1 \
        label.padding_left=2 \
        label.padding_right=2

    sketchybar --add item clock_sep right \
      --set clock_sep \
        icon.drawing=off \
        label="·" \
        label.font="CaskaydiaCove Nerd Font:Bold:18.0" \
        label.color=0xffbf616a \
        label.padding_left=4 \
        label.padding_right=4

    sketchybar --add item clock_h right \
      --set clock_h \
        update_freq=5 \
        script="${clockHScript}" \
        icon.drawing=off \
        label.font="CaskaydiaCove Nerd Font:Bold:18.0" \
        label.color=0xff8fbcbb \
        label.padding_left=18 \
        label.padding_right=0

    sketchybar --update

    # Trigger initial workspace highlight
    INIT_WS=$(aerospace list-workspaces --focused 2>/dev/null || echo "1")
    sketchybar --trigger aerospace_workspace_change AEROSPACE_FOCUSED_WORKSPACE="$INIT_WS"
  '';
in
lib.mkIf enableTilingWM {
  environment.systemPackages = [ pkgs.sketchybar ];

  system.activationScripts.postActivation.text = ''
    mkdir -p /usr/local/bin
    rm -f /usr/local/bin/sketchybar
    cp ${pkgs.sketchybar}/bin/sketchybar /usr/local/bin/sketchybar
    chmod +x /usr/local/bin/sketchybar
    echo "Copied sketchybar to /usr/local/bin"
  '';

  home-manager.users.${username} = {
    home.file.".config/sketchybar/sketchybarrc" = {
      source = sketchybarrc;
      executable = true;
    };
    home.file.".local/bin/sketchybar-bar-toggle" = {
      source = barToggleScript;
      executable = true;
    };
  };

  launchd.user.agents.sketchybar = {
    serviceConfig = {
      # Wait for the /nix APFS volume to mount, then exec the store binary
      # directly. RunAtLoad can fire before darwin-store mounts /nix, which
      # penalty-boxes the agent (EX_CONFIG) and KeepAlive never retries -> blank
      # bar all session. Pointing at /usr/local/bin/sketchybar has its own race:
      # activate-system rm's and re-cp's that copy on every boot. The /usr/local
      # copy still exists below for the aerospace trigger and bare `sketchybar`
      # calls in the config, which run later. (adapted from upstream reboot fix)
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "/bin/wait4path ${pkgs.sketchybar}/bin/sketchybar && exec ${pkgs.sketchybar}/bin/sketchybar"
      ];
      EnvironmentVariables = {
        PATH = "/usr/local/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/sketchybar.out.log";
      StandardErrorPath = "/tmp/sketchybar.err.log";
    };
  };
}
