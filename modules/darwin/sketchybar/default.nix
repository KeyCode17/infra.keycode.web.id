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
    WS_NUM="''${NAME#space.}"
    if [ "$AEROSPACE_FOCUSED_WORKSPACE" = "$WS_NUM" ]; then
      sketchybar --set "$NAME" \
        background.color=0xffc4a7e7 \
        background.height=26 \
        background.corner_radius=13 \
        icon.padding_left=9 \
        icon.padding_right=9 \
        icon.color=0xff191724
    else
      sketchybar --set "$NAME" \
        background.color=0x22e0def4 \
        background.height=12 \
        background.corner_radius=6 \
        icon.padding_left=4 \
        icon.padding_right=4 \
        icon.color=0x88908caa
    fi
  '';

  clockScript = pkgs.writeShellScript "sb-clock" ''
    sketchybar --set clock label="$(date +'%H:%M  %a %d %b')"
  '';

  wifiScript = pkgs.writeShellScript "sb-wifi" ''
    IP=$(ipconfig getifaddr en0 2>/dev/null)
    if [ -n "$IP" ]; then
      sketchybar --set wifi icon="󰤨" icon.color=0xff9ccfd8 label="$IP"
    else
      sketchybar --set wifi icon="󰤭" icon.color=0x886e6a86 label="off"
    fi
  '';

  volumeScript = pkgs.writeShellScript "sb-volume" ''
    VOL=$(osascript -e "output volume of (get volume settings)" 2>/dev/null)
    MUTED=$(osascript -e "output muted of (get volume settings)" 2>/dev/null)
    if [ "$MUTED" = "true" ]; then
      sketchybar --set volume icon="󰝟" icon.color=0x886e6a86 label="mute"
    else
      sketchybar --set volume icon="󰕾" icon.color=0xff9ccfd8 label="''${VOL}%"
    fi
  '';

  batteryScript = pkgs.writeShellScript "sb-battery" ''
    BATT=$(pmset -g batt 2>/dev/null | grep -o "[0-9]*%" | head -1 | tr -d "%")
    AC=$(pmset -g batt 2>/dev/null | grep -c "AC Power" || true)
    if [ "$AC" -gt 0 ]; then
      sketchybar --set battery icon="󰂄" icon.color=0xff9ccfd8 label="''${BATT}%"
    elif [ "''${BATT:-100}" -le 15 ]; then
      sketchybar --set battery icon="󰁺" icon.color=0xffeb6f92 label="''${BATT}%"
    else
      sketchybar --set battery icon="󰁾" icon.color=0xfff6c177 label="''${BATT}%"
    fi
  '';

  sketchybarrc = pkgs.writeShellScript "sketchybarrc" ''
    # Rosé Pine — sketchybar top bar (mirrors eww vertical bar)

    sketchybar --bar \
      position=top \
      height=44 \
      blur_radius=20 \
      color=0xe0191724 \
      border_width=0 \
      margin=0 \
      y_offset=0 \
      topmost=window

    sketchybar --default \
      updates=when_shown \
      icon.font="JetBrainsMono Nerd Font Mono:Regular:16.0" \
      icon.color=0xffc4a7e7 \
      icon.padding_left=4 \
      icon.padding_right=4 \
      label.font="JetBrainsMono Nerd Font:SemiBold:13.0" \
      label.color=0xffe0def4 \
      label.padding_left=4 \
      label.padding_right=4

    # Nix logo
    sketchybar --add item logo left \
      --set logo \
        icon="" \
        icon.color=0xffc4a7e7 \
        icon.font="JetBrainsMono Nerd Font Mono:Regular:22.0" \
        icon.padding_left=12 \
        icon.padding_right=8 \
        label.drawing=off

    # Register Aerospace workspace change event
    sketchybar --add event aerospace_workspace_change

    # Workspaces 1–9: subscribe to event, click switches workspace
    for i in 1 2 3 4 5 6 7 8 9; do
      sketchybar --add item "space.''${i}" left \
        --set "space.''${i}" \
          script="${spaceScript}" \
          click_script="aerospace workspace ''${i}" \
          icon="''${i}" \
          icon.font="JetBrainsMono Nerd Font:Bold:12.0" \
          icon.color=0x88908caa \
          icon.padding_left=4 \
          icon.padding_right=4 \
          background.color=0x22e0def4 \
          background.corner_radius=6 \
          background.height=12 \
          label.drawing=off \
          padding_left=2 \
          padding_right=2 \
        --subscribe "space.''${i}" aerospace_workspace_change
    done

    # WiFi
    sketchybar --add item wifi right \
      --set wifi \
        update_freq=10 \
        script="${wifiScript}" \
        icon="󰤨" \
        icon.color=0xff9ccfd8 \
        label="..."

    # Volume
    sketchybar --add item volume right \
      --set volume \
        update_freq=3 \
        script="${volumeScript}" \
        icon="󰕾" \
        icon.color=0xff9ccfd8 \
        label="..."

    # Battery
    sketchybar --add item battery right \
      --set battery \
        update_freq=30 \
        script="${batteryScript}" \
        icon="󰁾" \
        icon.color=0xfff6c177 \
        label="..."

    # Clock (leftmost on right side)
    sketchybar --add item clock right \
      --set clock \
        update_freq=5 \
        script="${clockScript}" \
        icon.drawing=off \
        label.font="JetBrainsMono Nerd Font:Bold:15.0" \
        label.color=0xffebbcba \
        label.padding_left=8 \
        label.padding_right=8

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
  };

  launchd.user.agents.sketchybar = {
    serviceConfig = {
      ProgramArguments = [ "/usr/local/bin/sketchybar" ];
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
