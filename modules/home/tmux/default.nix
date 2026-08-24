{
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./keybindings.nix
    ./theme.nix
  ];

  home-manager.users.${username} = {
    home.file.".local/bin/tmux-startup" = {
      executable = true;
      text = ''
        #!/bin/zsh

        # absolute path: kitty launched from AeroSpace/Finder does not
        # necessarily have the nix profile on PATH
        TMUX_BIN="${pkgs.tmux}/bin/tmux"

        # already inside tmux -> nothing to do
        [ -n "$TMUX" ] && exit 0

        # Cold server: continuum restores in the BACKGROUND (continuum.tmux ->
        # start_auto_restore_in_background, which sleeps 1s first). Racing it
        # would attach an empty bootstrap session while the restored one lands
        # beside it, so wait for the session count to appear and settle.
        cold=0
        if ! "$TMUX_BIN" has-session 2>/dev/null; then
          cold=1
          "$TMUX_BIN" start-server
          # only pay the wait when there is a snapshot to restore; resurrect
          # keeps `last` pointing at the newest one
          if [ -e "$HOME/.tmux/resurrect/last" ]; then
            prev=-1
            for _ in {1..16}; do
              sleep 0.25
              count="$("$TMUX_BIN" list-sessions 2>/dev/null | wc -l | tr -d ' ')"
              [ "$count" -gt 0 ] && [ "$count" = "$prev" ] && break
              prev="$count"
            done
          fi
        fi

        # Restored sessions all carry session_last_attached=0, so on a cold
        # server prefer the session that was active when the snapshot was
        # taken (resurrect records it on a `state` line).
        target=""
        if [ "$cold" = 1 ] && [ -e "$HOME/.tmux/resurrect/last" ]; then
          state_sess="$(awk -F'\t' '$1 == "state" { print $2; exit }' \
            "$HOME/.tmux/resurrect/last" 2>/dev/null)"
          if [ -n "$state_sess" ] && "$TMUX_BIN" has-session -t "=$state_sess" 2>/dev/null; then
            target="$state_sess"
          fi
        fi

        # otherwise attach whatever was used last
        [ -n "$target" ] || target="$("$TMUX_BIN" list-sessions -F '#{session_last_attached} #{session_name}' 2>/dev/null \
          | sort -rn | head -1 | cut -d' ' -f2-)"

        # nothing to attach (fresh machine, nothing restored) -> bootstrap the
        # defaults. Deliberately only here: creating them unconditionally would
        # clutter every launch with empty sessions next to the real one.
        if [ -z "$target" ]; then
          # zsh associative arrays take flat key/value pairs; the bash
          # ["key"]=value form is a parse error under zsh
          typeset -A SESSIONS
          SESSIONS=(
            nix  "$HOME/.config/nix"
            home "$HOME"
          )

          for name in nix home; do
            dir="''${SESSIONS[$name]}"
            [ -d "$dir" ] || dir="$HOME"
            "$TMUX_BIN" new-session -d -s "$name" -c "$dir"
          done
          target=nix
        fi

        exec "$TMUX_BIN" attach-session -t "=$target"
      '';
    };

    programs.tmux = {
      enable = true;
      shell = "${pkgs.zsh}/bin/zsh";
      terminal = "tmux-256color";
      historyLimit = 10000;
      escapeTime = 0;
      baseIndex = 1;
      keyMode = "vi";
      mouse = true;
      prefix = "C-Space";

      extraConfig = ''
        set -g default-command "${pkgs.zsh}/bin/zsh"
        set -g default-shell "${pkgs.zsh}/bin/zsh"
        set -ag terminal-overrides ",xterm-256color:RGB"
        set -g renumber-windows on
        set -g allow-rename off
        set -g mouse on
        setw -g mode-keys vi
      '';

      plugins = with pkgs.tmuxPlugins; [
        sensible
        yank
        {
          plugin = resurrect;
          extraConfig = ''
            set -g @resurrect-strategy-nvim 'session'
            set -g @resurrect-capture-pane-contents 'on'
          '';
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '1'
          '';
        }
      ];
    };
  };
}
