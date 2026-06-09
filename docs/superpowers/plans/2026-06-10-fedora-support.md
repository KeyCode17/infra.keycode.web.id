# Fedora Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Fedora as a third platform via home-manager standalone, managing user dotfiles + CLI packages without touching the existing NixOS/macOS/WSL entries.

**Architecture:** Small dotfile leaves are duplicated flat into `modules/home/fedora.nix`. The 761-line nixvim config is refactored into a flat inner layer (`neovim/config.nix`) plus a thin nested wrapper (`neovim/default.nix`) so the four existing consumers keep importing `./neovim` with byte-identical behavior, while Fedora imports the flat layer directly. A new `homeConfigurations.<user>` flake output ties it together.

**Tech Stack:** Nix flakes, home-manager (standalone), nixvim, clan-core (existing).

**Verification model:** This is Nix — "tests" are `nix eval` / `nix build` of flake outputs. A task's "failing test" is the build/eval command that errors before the change; "passing" is the same command succeeding after.

---

### Task 1: Refactor neovim subtree to flat layer + wrapper (zero behavior change)

Flatten every neovim config fragment from NixOS-module style
(`home-manager.users.${username}.programs.nixvim`) to flat home-manager style
(`programs.nixvim`), add a flat aggregator `config.nix`, and turn `default.nix`
into a thin nested wrapper. Existing consumers (`nixos.nix`, `darwin.nix`,
`wsl.nix`, `nixos-server.nix`) import `./neovim` unchanged.

**Files:**
- Modify: `modules/home/neovim/options.nix`
- Modify: `modules/home/neovim/keymaps.nix`
- Modify: `modules/home/neovim/plugins/colorscheme.nix`
- Modify: `modules/home/neovim/plugins/treesitter.nix`
- Modify: `modules/home/neovim/plugins/telescope.nix`
- Modify: `modules/home/neovim/plugins/lsp.nix`
- Modify: `modules/home/neovim/plugins/cmp.nix`
- Modify: `modules/home/neovim/plugins/ui.nix`
- Modify: `modules/home/neovim/plugins/formatting.nix`
- Modify: `modules/home/neovim/plugins/claudecode.nix`
- Modify: `modules/home/neovim/plugins/stynx.nix`
- Create: `modules/home/neovim/config.nix`
- Modify: `modules/home/neovim/default.nix`
- Unchanged: `modules/home/neovim/plugins/default.nix` (already flat)

- [ ] **Step 1: Capture the baseline (the "test")**

Record the current derivation hash of the workstation toplevel so we can prove the
refactor changes nothing. Run:

```bash
nix eval --raw .#nixosConfigurations.workstation.config.system.build.toplevel.drvPath
```

Save the output string. Expected: a `/nix/store/...-nixos-system-...drv` path. (If
eval errors for unrelated reasons, fall back to "it must still evaluate after".)

- [ ] **Step 2: Flatten the two top-level config files**

In `modules/home/neovim/options.nix`:
- Change line 1 from `{ username, ... }:` to `{ ... }:`
- Change line 3 from `  home-manager.users.${username}.programs.nixvim = {` to `  programs.nixvim = {`
- Leave the entire rest of the file unchanged.

In `modules/home/neovim/keymaps.nix`:
- Change line 1 from `{ username, ... }:` to `{ ... }:`
- Change line 2 from `  home-manager.users.${username}.programs.nixvim.keymaps = [` to `  programs.nixvim.keymaps = [`
- Leave the rest unchanged.

- [ ] **Step 3: Flatten the plugin files (no `pkgs`)**

For each of these files, change line 1 `{ username, ... }:` → `{ ... }:` and replace the
single `home-manager.users.${username}.programs.nixvim` prefix with `programs.nixvim`.
Leave all other lines unchanged.

- `plugins/colorscheme.nix`: prefix line becomes `  programs.nixvim.colorschemes.rose-pine = {`
- `plugins/treesitter.nix`: prefix line becomes `  programs.nixvim.plugins = {`
- `plugins/telescope.nix`: prefix line becomes `  programs.nixvim.plugins.telescope = {`
- `plugins/cmp.nix`: prefix line becomes `  programs.nixvim.plugins = {`
- `plugins/ui.nix`: prefix line becomes `  programs.nixvim.plugins = {`
- `plugins/formatting.nix`: prefix line becomes `  programs.nixvim.plugins = {`

- [ ] **Step 4: Flatten the plugin files that keep `pkgs`**

These use `pkgs`, so keep `pkgs` in the arg list — only drop `username`.

`plugins/claudecode.nix`:
- Line 1 `{ username, pkgs, ... }:` → `{ pkgs, ... }:`
- `  home-manager.users.${username}.programs.nixvim = {` → `  programs.nixvim = {`

`plugins/lsp.nix`:
- Line 1 `{ username, pkgs, ... }:` → `{ pkgs, ... }:`
- `  home-manager.users.${username}.programs.nixvim = {` → `  programs.nixvim = {`

`plugins/stynx.nix`:
- Line 1 `{ username, pkgs, ... }:` → `{ pkgs, ... }:`
- Line 40 `  home-manager.users.${username}.programs.nixvim = {` → `  programs.nixvim = {`
- Leave the `let ... in` block (lines 2-38) and the rest unchanged.

- [ ] **Step 5: Create the flat aggregator `config.nix`**

Create `modules/home/neovim/config.nix`:

```nix
{ pkgs, ... }:
{
  imports = [
    ./options.nix
    ./keymaps.nix
    ./plugins
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    version.enableNixpkgsReleaseCheck = false;

    extraPackages = with pkgs; [
      ripgrep
      fd
      prettierd
      stylua
      nixfmt
      eslint_d
    ];
  };
}
```

- [ ] **Step 6: Replace `default.nix` with the thin wrapper**

Overwrite `modules/home/neovim/default.nix` with:

```nix
{
  username,
  nixvim,
  ...
}:
{
  home-manager.users.${username}.imports = [
    nixvim.homeModules.nixvim
    ./config.nix
  ];
}
```

This preserves the exact module set the four existing consumers merged before
(nixvim home module + options + keymaps + plugins + core `programs.nixvim`), now
routed through `config.nix`.

- [ ] **Step 7: Verify existing outputs are unchanged (the "test passes")**

Run:

```bash
nix eval --raw .#nixosConfigurations.workstation.config.system.build.toplevel.drvPath
```

Expected: **the same** `.drv` path string captured in Step 1. If it differs, the
flatten introduced a behavior change — diff the offending file against git and fix.
Also confirm it still evaluates without error (no `username` undefined, etc.).

- [ ] **Step 8: Commit**

```bash
git add modules/home/neovim
git commit -m "refactor: split nixvim into flat config.nix + nested wrapper"
```

---

### Task 2: Add Fedora config fields and wire them into the flake

**Files:**
- Modify: `config.nix`
- Modify: `config.local.nix`
- Modify: `flake.nix` (the `inherit (config) ...` block, around line 201-208)

- [ ] **Step 1: Add placeholder fields to `config.nix`**

In `config.nix`, after the `wslHostname` line (line 11), add:

```nix
  fedoraUsername = "your-username";
  fedoraHostname = "fedora";
```

- [ ] **Step 2: Add real fields to `config.local.nix`**

In `config.local.nix`, after the `wslHostname` line (line 11), add:

```nix
  fedoraUsername = "keycode";
  fedoraHostname = "fedora";
```

- [ ] **Step 3: Expose `fedoraUsername` in the flake `let` block**

In `flake.nix`, find the `inherit (config)` block (starts ~line 201):

```nix
      inherit (config)
        sshKeys
        acmeEmail
        enableLaravel
        enableRust
        enableVolta
        enableGolang
        ;
```

Add `fedoraUsername` to the list:

```nix
      inherit (config)
        sshKeys
        acmeEmail
        enableLaravel
        enableRust
        enableVolta
        enableGolang
        fedoraUsername
        ;
```

- [ ] **Step 4: Verify the flake still evaluates**

Run:

```bash
nix eval .#nixosConfigurations.workstation.config.system.build.toplevel.drvPath >/dev/null && echo OK
```

Expected: `OK` (no eval error from the new bindings).

- [ ] **Step 5: Commit**

```bash
git add config.nix config.local.nix flake.nix
git commit -m "feat: add fedoraUsername/fedoraHostname config fields"
```

---

### Task 3: Create the Fedora home-manager config and flake output

**Files:**
- Create: `hosts/fedora/default.nix`
- Create: `modules/home/fedora.nix`
- Modify: `flake.nix` (add `home-manager.lib` to outputs args + `homeConfigurations` output)

- [ ] **Step 1: Create the machine entry `hosts/fedora/default.nix`**

```nix
{ username, ... }:
{
  imports = [ ../../modules/home/fedora.nix ];

  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
}
```

- [ ] **Step 2: Create `modules/home/fedora.nix`**

Flat, self-contained dotfiles + packages. Copied from the existing leaves with
macOS-isms removed (`pbcopy` → `wl-copy`, Laravel/`build-system` aliases dropped,
`authorized_keys` dropped — Fedora manages those).

```nix
{ pkgs, nixvim, claude-code, ... }:
{
  imports = [
    nixvim.homeModules.nixvim
    ./neovim/config.nix
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

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        extraOptions = {
          AddKeysToAgent = "yes";
        };
      };
    };
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
    prefix = "C-a";

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
      set -g status-style 'bg=#191724 fg=#e0def4'
      set -g pane-border-style 'fg=#26233a'
      set -g pane-active-border-style 'fg=#c4a7e7'
      set -g status-left-length 40
      set -g status-right-length 100
      set -g status-left '#[fg=#191724,bg=#c4a7e7,bold] #S #[fg=#c4a7e7,bg=#191724]'
      set -g status-right '#[fg=#26233a,bg=#191724]#[fg=#e0def4,bg=#26233a] %H:%M #[fg=#c4a7e7,bg=#26233a]#[fg=#191724,bg=#c4a7e7,bold] %d-%m-%Y '
      set -g window-status-current-format '#[fg=#191724,bg=#c4a7e7]#[fg=#191724,bg=#c4a7e7,bold] #I #W #[fg=#c4a7e7,bg=#191724]'
      set -g window-status-format '#[fg=#6e6a86,bg=#191724] #I #W '
      set -g message-style 'fg=#e0def4 bg=#26233a'
      set -g message-command-style 'fg=#e0def4 bg=#26233a'
      set -g mode-style 'fg=#e0def4 bg=#26233a'
    '';
  };

  # Neovim (nixvim) is fully provided by the ./neovim/config.nix import above
  # (enable, options, keymaps, plugins, extraPackages). Do not redefine
  # programs.nixvim here — that would create a module merge conflict.

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

      claude-code.packages.${pkgs.system}.default
    ];
  };
}
```

- [ ] **Step 3: Add `home-manager` lib to the outputs function args**

In `flake.nix`, the `outputs = { self, nixpkgs, nix-darwin, home-manager, ... }:`
already destructures `home-manager` (line 155). No change needed — confirm it is
present in the args list.

- [ ] **Step 4: Add the `homeConfigurations` output**

In `flake.nix`, inside the returned attrset (the `in { ... }` block, after the
`nixOnDroidConfigurations.android` block ~line 445 and before `devShells`), add:

```nix
      homeConfigurations.${fedoraUsername} = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        extraSpecialArgs = {
          username = fedoraUsername;
          inherit nixvim claude-code;
        };
        modules = [ ./hosts/fedora ];
      };
```

- [ ] **Step 5: Build the Fedora config (the "test")**

```bash
nix build .#homeConfigurations.keycode.activationPackage --no-link --print-out-paths
```

Expected: a `/nix/store/...-home-manager-generation` path, no errors. First run
compiles `stynx-cli` (Rust) and fetches plugins — may take several minutes.

- [ ] **Step 6: Commit**

```bash
git add hosts/fedora modules/home/fedora.nix flake.nix
git commit -m "feat: add Fedora home-manager standalone config"
```

---

### Task 4: Document Fedora in the README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add a Fedora section**

Add the following section to `README.md` (after the macOS/NixOS usage sections;
place it logically near the other platform instructions):

````markdown
### Fedora (home-manager standalone)

Fedora keeps its own kernel, system, and desktop. Nix manages only your user
environment (dotfiles + CLI packages).

1. Install Nix (Determinate installer):

   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

2. First-time apply (bootstraps home-manager):

   ```bash
   nix run home-manager/master -- switch --flake .#keycode
   ```

3. Subsequent updates:

   ```bash
   home-manager switch --flake .#keycode
   ```

Replace `keycode` with your `fedoraUsername` from `config.local.nix`.
````

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add Fedora home-manager setup instructions"
```

---

## Self-Review Notes

- **Spec coverage:** neovim refactor (Task 1), config fields (Task 2), `hosts/fedora`
  + `modules/home/fedora.nix` + flake output (Task 3), README (Task 4). devShell
  rebuild extension was marked low-priority/optional in the spec and is intentionally
  deferred (YAGNI) — not blocking.
- **Zero-touch guarantee:** verified in Task 1 Step 7 by comparing the workstation
  toplevel `.drvPath` before/after.
- **Known first-build cost:** `stynx-cli` Rust compile + plugin fetches on first
  `nix build` (Task 3 Step 5).
- **Fallback documented:** nixvim attribute-merge conflict handling in Task 3.
