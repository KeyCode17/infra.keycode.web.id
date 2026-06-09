# Fedora Support via home-manager standalone

**Date:** 2026-06-10
**Status:** Approved design, pending spec review

## Goal

Add Fedora as a third first-class platform alongside NixOS and macOS. Fedora keeps
its own kernel, system, and desktop environment. Nix manages only the **user
environment** (dotfiles + CLI packages) via **home-manager standalone**.

Apply with:

```bash
home-manager switch --flake .#keycode
```

## Non-Goals

- No system-level / declarative OS management on Fedora (impossible without NixOS).
- No window manager / Wayland / Hyprland (use Fedora's GNOME/KDE).
- No GUI packages in v1 (CLI only).
- No refactor of the NixOS/macOS/WSL entry points.

## Decisions (locked)

| Topic | Choice |
|-------|--------|
| Scope | CLI dotfiles + packages only |
| Dotfile leaves (git/zsh/tmux/ssh/starship) | **Duplicate** flat into `modules/home/fedora.nix` |
| Neovim (nixvim, 761 lines) | **Refactor neovim subtree** to a flat layer + thin wrapper; reuse on all platforms |
| Username / home | `keycode` / `/home/keycode` |
| Git identity | `KeyCode17` / `m.daffa.karyudi@gmail.com` |
| Package set | Mirror `modules/home/wsl.nix` CLI set |
| Layout | `hosts/fedora/default.nix` imports `modules/home/fedora.nix` |
| Flake output | `homeConfigurations.keycode` |

## Architecture

### The core constraint

Every existing shared leaf module nests config under
`home-manager.users.${username}.<...>` — the NixOS/darwin **module** style.
Standalone home-manager configs are **flat** (`programs.git = {...}` at top level).
The two shapes are incompatible, so reuse requires either duplication (small leaves)
or a flat inner layer (neovim).

### Neovim refactor (zero touch to existing entries)

The 761-line nixvim config is too large to duplicate. Split it so the existing four
consumers (`nixos.nix`, `darwin.nix`, `wsl.nix`, `nixos-server.nix`) keep importing
`./neovim` with identical external behavior, while Fedora imports the flat inner
layer directly.

```
modules/home/neovim/
  default.nix     # MODIFIED -> thin NESTED wrapper (for existing consumers)
  config.nix      # NEW      -> flat layer: imports options/keymaps/plugins + core programs.nixvim
  options.nix     # MODIFIED -> flatten: programs.nixvim = {...}      (drop home-manager.users.${username})
  keymaps.nix     # MODIFIED -> flatten: programs.nixvim.keymaps = [...]
  plugins/
    default.nix   # unchanged (already flat: just imports)
    *.nix         # MODIFIED -> flatten each (colorscheme/treesitter/telescope/lsp/cmp/ui/formatting/claudecode/stynx)
```

**`config.nix` (NEW, flat HM module):**
```nix
{ pkgs, ... }:
{
  imports = [ ./options.nix ./keymaps.nix ./plugins ];
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    version.enableNixpkgsReleaseCheck = false;
    extraPackages = with pkgs; [ ripgrep fd prettierd stylua nixfmt eslint_d ];
  };
}
```

**`default.nix` (MODIFIED, thin nested wrapper — existing consumers unchanged):**
```nix
{ username, nixvim, ... }:
{
  home-manager.users.${username}.imports = [
    nixvim.homeModules.nixvim
    ./config.nix
  ];
}
```

Existing entries still do `imports = [ ... ./neovim ]` and pass `username` + `nixvim`
via `_module.args` / specialArgs exactly as today. No change to those four files.

### Fedora entry points (NEW)

**`hosts/fedora/default.nix`** — machine wiring (identity), mirrors the `hosts/*`
convention:
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

**`modules/home/fedora.nix`** — flat, self-contained dotfiles + packages
(duplicates the small leaves; imports the flat neovim layer):
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

  programs.zsh = { /* oh-my-zsh robbyrussell, autosuggestion, syntaxHighlighting,
                       history, shellAliases (copied from zsh/aliases.nix,
                       Laravel aliases omitted) */ };
  programs.starship = { enable = true; enableZshIntegration = true; };
  programs.tmux = { /* copied from tmux/default.nix incl keybindings + theme */ };
  programs.ssh = { /* enable, AddKeysToAgent; no authorized_keys (managed by Fedora) */ };

  home = {
    sessionVariables = { EDITOR = "nvim"; GOPATH = "$HOME/go"; };
    sessionPath = [ "$HOME/.local/bin" "$HOME/go/bin" "$HOME/.bun/bin" ];
    packages = with pkgs; [
      eza bat fzf zoxide ripgrep fd jq yq
      nodejs_22 pnpm bun go python3
      docker-compose lazydocker
      lazygit gh delta
      ncdu duf procs bottom htop tldr
      httpie xh
      p7zip unrar
      imagemagick ffmpeg
      claude-code.packages.${pkgs.system}.default
    ];
  };
}
```

Notes:
- tmux `tmux-startup` script references macOS-specific dirs; for Fedora keep the
  tmux config but drop / simplify the startup script (or keep, harmless). Decision:
  copy tmux program config, omit the `tmux-startup` file to avoid dead paths.
- zsh aliases: copy the generic set; omit Laravel block and the
  `build-system`/`init-*` aliases that assume `~/.config/nix` darwin paths (or keep
  `init-*` pointing at this repo path). Decision: keep `init-*` but omit
  `build-system` (darwin-only).

### Flake output (NEW)

In `flake.nix` `outputs`, add alongside `nixosConfigurations`:
```nix
homeConfigurations.${config.fedoraUsername} = home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
  extraSpecialArgs = {
    username = config.fedoraUsername;
    inherit nixvim claude-code;
  };
  modules = [ ./hosts/fedora ];
};
```

### Config fields (NEW)

Add to **both** `config.nix` (placeholder) and `config.local.nix` (real):
```nix
fedoraUsername = "keycode";   # config.nix: "your-username"
fedoraHostname = "fedora";
```
Wire `fedoraUsername` into the `inherit (config) ...` list and `homeConfigurations`.

### devShell (optional)

Extend the `rebuild` script in `flake.nix` devShell to detect Fedora (non-NixOS
Linux) and run `home-manager switch --flake .#<user>` instead of `nixos-rebuild`.
Low priority; can be a follow-up.

### README

Add a **Fedora** section: install Determinate Nix, enable flakes, first-time
`nix run home-manager/master -- switch --flake .#keycode`, then
`home-manager switch --flake .#keycode`.

## Files Summary

**New:**
- `hosts/fedora/default.nix`
- `modules/home/fedora.nix`
- `modules/home/neovim/config.nix`

**Modified:**
- `modules/home/neovim/default.nix` (-> thin wrapper)
- `modules/home/neovim/options.nix`, `keymaps.nix` (flatten)
- `modules/home/neovim/plugins/{colorscheme,treesitter,telescope,lsp,cmp,ui,formatting,claudecode,stynx}.nix` (flatten)
- `flake.nix` (homeConfigurations output + fedoraUsername inherit + home-manager.lib)
- `config.nix`, `config.local.nix` (fedora fields)
- `README.md` (Fedora section)

**Untouched (verified):** `nixos.nix`, `darwin.nix`, `wsl.nix`, `nixos-server.nix`.

## Verification

1. `nix flake check` (or at least `nix eval .#homeConfigurations.keycode.activationPackage.drvPath`)
2. `nix build .#homeConfigurations.keycode.activationPackage` — must build.
3. Regression: `nix build .#nixosConfigurations.workstation.config.system.build.toplevel`
   (or `nix flake check`) to confirm the neovim refactor didn't change existing
   outputs. Darwin can't be built on Linux — rely on the wrapper being externally
   identical + flake eval.
4. Actual apply on this machine: `home-manager switch --flake .#keycode`.

## Risks

- **Neovim flatten typo** breaks all platforms. Mitigation: the wrapper keeps the
  exact same imported module set; build the workstation toplevel to catch eval errors.
- **nixvim release-check / unfree** on standalone pkgs. Mitigation: `allowUnfree` set
  in the `homeConfigurations` pkgs; `version.enableNixpkgsReleaseCheck = false`.
- **claude-code package** for `x86_64-linux` must exist (it does — used by wsl).
