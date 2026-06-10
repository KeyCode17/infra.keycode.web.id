{ pkgs, nixvim, claude-code, ... }:
{
  imports = [
    nixvim.homeModules.nixvim
    ./neovim/config.nix
    ./fedora-hyprland
  ];

  programs.git = {
    enable = true;
    settings = {
      user.name = "KeyCode17";
      user.email = "m.daffa.karyudi@gmail.com";
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
    };

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "z"
        "docker"
      ];
    };

    shellAliases = {
      c = "clear";
      v = "nvim";
      cl = "claude";

      ls = "eza --icons";
      ll = "eza -la --icons";
      la = "eza -a --icons";
      lt = "eza --tree --icons";
      l = "eza -l --icons";
      cat = "bat";

      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      gco = "git checkout";
      gcb = "git checkout -b";
    };

    initContent = ''
      bindkey '^[[A' history-search-backward
      bindkey '^[[B' history-search-forward

      if command -v fzf &> /dev/null; then
        eval "$(fzf --zsh)"
      fi

      export PATH="$HOME/.cargo/bin:$PATH"
    '';
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # NOTE: ssh config is managed manually outside home-manager (a real ~/.ssh/config
  # with custom hosts). Leaving programs.ssh off so HM doesn't clobber it.

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

    extraConfig = ''
      set -g default-command "${pkgs.zsh}/bin/zsh"
      set -g default-shell "${pkgs.zsh}/bin/zsh"
      set -ag terminal-overrides ",xterm-256color:RGB"
      set -g renumber-windows on
      set -g allow-rename off
      set -g mouse on
      setw -g mode-keys vi

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
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "wl-copy"
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "wl-copy"

      bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'select-pane -t=; copy-mode -e; send-keys -M'"
      bind -n WheelDownPane select-pane -t= \; send-keys -M
      bind [ copy-mode

      set -g @rose_pine_variant 'main'
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
  };

  # Neovim (nixvim) is fully provided by the ./neovim/config.nix import above
  # (enable, options, keymaps, plugins, extraPackages). Do not redefine
  # programs.nixvim here -- that would create a module merge conflict.

  # Make nix-installed fonts discoverable to fontconfig (kitty, GTK, etc).
  fonts.fontconfig.enable = true;

  home = {
    sessionVariables = {
      EDITOR = "nvim";
      GOPATH = "$HOME/go";
    };

    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/go/bin"
      "$HOME/.bun/bin"
    ];

    packages = with pkgs; [
      eza
      bat
      fzf
      zoxide
      ripgrep
      fd
      jq
      yq

      nodejs_22
      pnpm
      bun
      go
      python3

      docker-compose
      lazydocker

      lazygit
      gh
      delta

      ncdu
      duf
      procs
      bottom
      htop
      tldr

      httpie
      xh

      p7zip
      unrar

      imagemagick
      ffmpeg

      wl-clipboard

      # Fonts referenced across the config (terminal, neovim, bar, GTK)
      nerd-fonts.caskaydia-cove

      claude-code.packages.${pkgs.system}.default
    ];
  };
}
