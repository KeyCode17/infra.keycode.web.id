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

        declare -A SESSIONS
        SESSIONS=(
          ["nix"]="$HOME/.config/nix"
          ["home"]="$HOME"
        )

        SESSION_ORDER=("nix" "home")

        for name in "''${SESSION_ORDER[@]}"; do
          dir="''${SESSIONS[$name]}"
          if ! tmux has-session -t "$name" 2>/dev/null; then
            if [ -d "$dir" ]; then
              tmux new-session -d -s "$name" -c "$dir"
            else
              tmux new-session -d -s "$name" -c "$HOME"
            fi
          fi
        done

        if [ -z "$TMUX" ]; then
          tmux attach-session -t "nix"
        fi
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
