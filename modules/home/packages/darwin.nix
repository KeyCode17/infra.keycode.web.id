{
  pkgs,
  lib,
  username,
  enableRust,
  enableVolta,
  enableGolang,
  ...
}:
{
  home-manager.users.${username} = {
    home.packages =
      with pkgs;
      [
        ripgrep
        fd
        fzf
        eza
        bat
        htop
        jq
        tree
        lazygit
        lazydocker
        bun
        ffmpeg
        cmake
        ninja
        meson
        pkg-config
        ccache
        bear
        android-tools
      ]
      ++ lib.optionals enableRust [ rustup ]
      ++ lib.optionals enableVolta [ volta ]
      ++ lib.optionals enableGolang [
        go
        gopls
      ];

    home.sessionVariables = {
      NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    }
    // lib.optionalAttrs enableRust {
      RUSTUP_HOME = "$HOME/.rustup";
      CARGO_HOME = "$HOME/.cargo";
    }
    // lib.optionalAttrs enableVolta {
      VOLTA_HOME = "$HOME/.volta";
    }
    // lib.optionalAttrs enableGolang {
      GOPATH = "$HOME/go";
      GOBIN = "$HOME/go/bin";
    };

    home.sessionPath = [
      "$HOME/.bun/bin"
      "$HOME/.npm-global/bin"
    ]
    ++ lib.optionals enableRust [ "$HOME/.cargo/bin" ]
    ++ lib.optionals enableVolta [ "$HOME/.volta/bin" ]
    ++ lib.optionals enableGolang [ "$HOME/go/bin" ];
  };
}
