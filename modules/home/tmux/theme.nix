{ username, ... }:
{
  home-manager.users.${username}.programs.tmux.extraConfig = ''
    set -g status-position bottom
    set -g status-justify left
    set -g status-style 'bg=#2e3440 fg=#d8dee9'
    set -g pane-border-style 'fg=#3b4252'
    set -g pane-active-border-style 'fg=#81a1c1'
    set -g status-left-length 40
    set -g status-right-length 100
    set -g status-left '#[fg=#2e3440,bg=#81a1c1,bold] #S #[fg=#81a1c1,bg=#2e3440]'
    set -g status-right '#[fg=#3b4252,bg=#2e3440]#[fg=#d8dee9,bg=#3b4252] %H:%M #[fg=#81a1c1,bg=#3b4252]#[fg=#2e3440,bg=#81a1c1,bold] %d-%m-%Y '
    set -g window-status-current-format '#[fg=#2e3440,bg=#81a1c1]#[fg=#2e3440,bg=#81a1c1,bold] #I #W #[fg=#81a1c1,bg=#2e3440]'
    set -g window-status-format '#[fg=#4c566a,bg=#2e3440] #I #W '
    set -g message-style 'fg=#d8dee9 bg=#3b4252'
    set -g message-command-style 'fg=#d8dee9 bg=#3b4252'
    set -g mode-style 'fg=#d8dee9 bg=#3b4252'
  '';
}
