{ pkgs, username, ... }:
let
  # clipboard copy differs per platform: macOS pbcopy, Linux wayland wl-copy
  copyCmd = if pkgs.stdenv.isDarwin then "pbcopy" else "wl-copy";
in
{
  home-manager.users.${username}.programs.tmux.extraConfig = ''
    bind | split-window -h -c "#{pane_current_path}"
    bind - split-window -v -c "#{pane_current_path}"
    unbind '"'
    unbind %

    bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

    bind h select-pane -L
    bind j select-pane -D
    bind k select-pane -U
    bind l select-pane -R

    bind -r H resize-pane -L 5
    bind -r J resize-pane -D 5
    bind -r K resize-pane -U 5
    bind -r L resize-pane -R 5

    bind-key -T copy-mode-vi v send-keys -X begin-selection
    bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "${copyCmd}"
    bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "${copyCmd}"

    bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'select-pane -t=; copy-mode -e; send-keys -M'"
    bind -n WheelDownPane select-pane -t= \; send-keys -M
    bind [ copy-mode
  '';
}
