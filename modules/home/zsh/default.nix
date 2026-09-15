{
  username,
  ...
}:
{
  imports = [
    ./aliases.nix
  ];

  home-manager.users.${username} = {
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

      initContent = ''
        bindkey '^[[A' history-search-backward
        bindkey '^[[B' history-search-forward

        if command -v fzf &> /dev/null; then
          eval "$(fzf --zsh)"
        fi

        export PATH="$HOME/.cargo/bin:$PATH"

        # Claude Code's github MCP plugin expands GITHUB_PERSONAL_ACCESS_TOKEN
        # into its Authorization header. Source it from the gh CLI keychain
        # instead of storing a token on disk. Verified: gh's OAuth token
        # authenticates against https://api.githubcopilot.com/mcp/.
        if command -v gh &> /dev/null; then
          GH_MCP_TOKEN="$(gh auth token 2>/dev/null)"
          [ -n "$GH_MCP_TOKEN" ] && export GITHUB_PERSONAL_ACCESS_TOKEN="$GH_MCP_TOKEN"
          unset GH_MCP_TOKEN
        fi

        # Codex CLI reads DEEPSEEK_API_KEY (config.toml env_key) for the
        # DeepSeek model provider. Source it from the macOS keychain
        # instead of storing the key on disk.
        if command -v security &> /dev/null; then
          DEEPSEEK_KEY="$(security find-generic-password -a "$USER" -s DEEPSEEK_API_KEY -w 2>/dev/null)"
          [ -n "$DEEPSEEK_KEY" ] && export DEEPSEEK_API_KEY="$DEEPSEEK_KEY"
          unset DEEPSEEK_KEY
        fi

        # bare `tmux` reattaches the most recently used session instead of
        # spawning a fresh one; subcommands (ls, kill-server, ...) pass through
        tmux() {
          if [[ $# -eq 0 && -z "$TMUX" ]]; then
            ~/.local/bin/tmux-startup
          else
            command tmux "$@"
          fi
        }
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
  };
}
