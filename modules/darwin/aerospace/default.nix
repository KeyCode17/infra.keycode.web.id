{
  pkgs,
  lib,
  username,
  enableTilingWM,
  ...
}:
let
  # Caffeine toggle — mirrors Fedora Hyprland `caffeine` (stop/start idle daemon).
  # Backgrounds a `caffeinate` process AND flips pmset's disablesleep so the
  # machine also stays awake with the lid closed; notifies on each switch.
  #
  # State of record is pmset's SleepDisabled, NOT the pidfile: a stale pidfile
  # (crashed caffeinate, reused PID) would otherwise latch the toggle into the
  # ON branch forever, leaving sleep disabled with no way to clear it.
  # modules/darwin/sketchybar/default.nix reads the same flag for its icon.
  caffeineToggle = pkgs.writeShellScript "caffeine-toggle" ''
    PIDFILE="/tmp/caffeine-toggle.pid"

    stop_caffeinate() {
      if [ -f "$PIDFILE" ]; then
        kill "$(cat "$PIDFILE")" 2>/dev/null
        rm -f "$PIDFILE"
      fi
    }

    if /usr/bin/pmset -g | grep -qE 'SleepDisabled[[:space:]]+1'; then
      stop_caffeinate
      /usr/bin/sudo -n /usr/bin/pmset -a disablesleep 0
      /usr/bin/osascript -e 'display notification "Normal idle & lid sleep restored" with title "Caffeine OFF"'
    else
      # drop any leftover process first so a failed pmset cannot leak caffeinates
      stop_caffeinate
      # -i prevent idle system sleep, -s prevent sleep on AC. Deliberately no
      # -d/-u: those assert "display must stay on", and the point of caffeine
      # here is a machine that keeps working while the screen goes dark.
      /usr/bin/caffeinate -is &
      echo $! > "$PIDFILE"
      if /usr/bin/sudo -n /usr/bin/pmset -a disablesleep 1; then
        /usr/bin/osascript -e 'display notification "System & lid-close sleep disabled; screen still dims off" with title "☕ Caffeine ON"'
      else
        /usr/bin/osascript -e 'display notification "Idle lock disabled, but pmset failed — lid close still sleeps" with title "☕ Caffeine PARTIAL"'
      fi
    fi
    # Refresh the sketchybar coffee indicator immediately (if bar is running).
    /usr/local/bin/sketchybar --trigger caffeine_change 2>/dev/null || true
  '';

  # /tmp is not cleared at boot on macOS and disablesleep survives a reboot, so
  # a machine rebooted while caffeine was ON would come back with sleep disabled
  # and a stale pidfile. Reset all of it at every boot.
  #
  # RunAtLoad also fires when the daemon is (re)loaded by a darwin-rebuild
  # switch, i.e. while a caffeinate may genuinely be running. Killing it before
  # dropping the pidfile is what keeps that from orphaning the process: caffeine
  # simply lands OFF after every switch, which is at least consistent.
  caffeineBootReset = pkgs.writeShellScript "caffeine-boot-reset" ''
    if [ -f /tmp/caffeine-toggle.pid ]; then
      kill "$(cat /tmp/caffeine-toggle.pid)" 2>/dev/null
      rm -f /tmp/caffeine-toggle.pid
    fi
    /usr/bin/pmset -a disablesleep 0
  '';

  aerospaceConfig = pkgs.writeText "aerospace.toml" ''
    # Nord — Aerospace tiling WM
    # Keybinds mirror workstation (Hyprland/SUPER → macOS/cmd)

    # Startup is owned by the nix-managed launchd agent below (RunAtLoad +
    # KeepAlive), NOT AeroSpace's own login item, which macOS can silently leave
    # unapproved across reboots -> no tiling gaps on boot.
    start-at-login = false

    exec-on-workspace-change = [
      '/bin/bash', '-c',
      "/usr/local/bin/sketchybar --trigger aerospace_workspace_change AEROSPACE_FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE"
    ]

    [key-mapping]
    preset = 'qwerty'

    [gaps]
    inner.horizontal = 8
    inner.vertical   = 8
    outer.left       = 16
    outer.bottom     = 16
    outer.top        = 20
    outer.right      = 16

    [mode.main.binding]
    # Terminal / launcher
    alt-enter   = 'exec-and-forget open -n $HOME/Applications/Home\ Manager\ Trampolines/kitty.app'
    alt-d       = 'exec-and-forget open -a Raycast'
    alt-b       = 'exec-and-forget open -a Helium'
    # File manager. Fedora binds this to $mod+E; alt-e is taken by the layout
    # command here, so it lands on alt-shift-e instead.
    alt-shift-e = 'exec-and-forget open -a Finder'

    # Window focus (vim-style, mirrors $mod + hjkl on workstation)
    alt-h = 'focus left'
    alt-j = 'focus down'
    alt-k = 'focus up'
    alt-l = 'focus right'

    # Window move
    alt-shift-h = 'move left'
    alt-shift-j = 'move down'
    alt-shift-k = 'move up'
    alt-shift-l = 'move right'

    # Window resize
    alt-ctrl-h = 'resize width -50'
    alt-ctrl-j = 'resize height +50'
    alt-ctrl-k = 'resize height -50'
    alt-ctrl-l = 'resize width +50'

    # Workspace switch
    alt-1 = 'workspace 1'
    alt-2 = 'workspace 2'
    alt-3 = 'workspace 3'
    alt-4 = 'workspace 4'
    alt-5 = 'workspace 5'
    alt-6 = 'workspace 6'
    alt-7 = 'workspace 7'
    alt-8 = 'workspace 8'
    alt-9 = 'workspace 9'

    # Move window to workspace + follow
    alt-shift-1 = ['move-node-to-workspace 1', 'workspace 1']
    alt-shift-2 = ['move-node-to-workspace 2', 'workspace 2']
    alt-shift-3 = ['move-node-to-workspace 3', 'workspace 3']
    alt-shift-4 = ['move-node-to-workspace 4', 'workspace 4']
    alt-shift-5 = ['move-node-to-workspace 5', 'workspace 5']
    alt-shift-6 = ['move-node-to-workspace 6', 'workspace 6']
    alt-shift-7 = ['move-node-to-workspace 7', 'workspace 7']
    alt-shift-8 = ['move-node-to-workspace 8', 'workspace 8']
    alt-shift-9 = ['move-node-to-workspace 9', 'workspace 9']

    # Layout
    alt-t       = 'layout floating tiling'
    alt-shift-f = 'fullscreen'
    alt-e       = 'layout tiles horizontal vertical'
    alt-r       = 'layout accordion horizontal vertical'

    # Window / system
    alt-shift-q = 'close'
    alt-shift-b = 'exec-and-forget /Users/karyudi/.local/bin/sketchybar-bar-toggle'
    cmd-shift-x = 'exec-and-forget /Users/karyudi/.local/bin/caffeine-toggle'
    alt-ctrl-0  = 'exec-and-forget pmset displaysleepnow'
    alt-shift-r = 'reload-config'
  '';
in
lib.mkIf enableTilingWM {
  environment.systemPackages = [
    pkgs.aerospace
    pkgs.jankyborders
  ];

  # Install ~/.aerospace.toml as a WRITABLE copy (not a read-only nix symlink) so
  # the Alt+Shift+B bar toggle can rewrite `outer.top` at runtime + reload-config.
  # Re-copied (reset to the default 20px gap) on every rebuild.
  home-manager.users.${username} = {
    home.file.".local/bin/caffeine-toggle" = {
      source = caffeineToggle;
      executable = true;
    };

    imports = [
      (
        { lib, ... }:
        {
          home.activation.aerospaceWritableConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            rm -f "$HOME/.aerospace.toml"
            install -m 0644 ${aerospaceConfig} "$HOME/.aerospace.toml"
          '';
        }
      )
    ];
  };

  launchd.daemons.caffeine-boot-reset = {
    serviceConfig = {
      ProgramArguments = [ "${caffeineBootReset}" ];
      RunAtLoad = true;
    };
  };

  launchd.user.agents.borders = {
    serviceConfig = {
      ProgramArguments = [
        "/run/current-system/sw/bin/borders"
        "width=2.0"
        # iris -> rose gradient, matching Fedora Hyprland's col.active_border
        "active_color=gradient(top_left=0xff81a1c1,bottom_right=0xff8fbcbb)"
        "inactive_color=0xff434c5e"
        "blur_radius=0"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/borders.out.log";
      StandardErrorPath = "/tmp/borders.err.log";
    };
  };

  # Launch AeroSpace from a nix-managed agent instead of its own login item
  # (macOS can leave that unapproved across reboots -> no tiling gaps). KeepAlive
  # restarts it if it dies; wait4path guards the /nix mount race the same way the
  # sketchybar agent does. (adapted from upstream reboot-survival fix)
  launchd.user.agents.aerospace = {
    serviceConfig = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "/bin/wait4path ${pkgs.aerospace}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace && exec ${pkgs.aerospace}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/aerospace.out.log";
      StandardErrorPath = "/tmp/aerospace.err.log";
    };
  };
}
