# Nord theme + shortcuts for macOS & NixOS

**Date:** 2026-06-19
**Status:** Approved design, pending spec review
**Branch:** `feat/nord-mac-nixos`

## Goal

Bring the user's **Nord theme** and **shortcuts** (already built for Fedora) to the
**macOS (nix-darwin)** and **NixOS workstation** configs, while keeping the app/tech
stack identical to upstream. No new apps, no package-set changes beyond a few tools
the desktop needs.

## Scope (locked decisions)

| Platform | What changes |
|----------|--------------|
| **Shared** (tmux, neovim) | Nord colors + tmux prefix `Ctrl+Space` + Fedora binds; neovim Nord colorscheme. Affects Mac/NixOS/WSL/VPS — accepted. |
| **macOS** | Recolor only → Nord: kitty, ghostty, sketchybar, aerospace borders. No keybind/app changes (aerospace shortcuts already mirror the Hyprland style with `Alt` as mod). |
| **NixOS** | Full port of the Fedora Hyprland desktop → Nord + all features, adapted for NixOS (nested HM, native Hyprland, no NVIDIA/PATH/systemd hacks). + GTK Nord. |

**Approach: B (overhaul NixOS separately; leave Fedora untouched).** Fedora is in
daily use and cannot be GUI-tested from here, so the working config is not refactored.
Some duplication between `modules/home/fedora-hyprland` (flat) and
`modules/home/hyprland` (nested) is accepted; sync manually later if desired.

## Nord palette (reference)

```
bg      #2e3440   surface #3b4252   overlay #3b4252   highlight #434c5e
muted   #4c566a   text    #d8dee9
red     #bf616a   gold    #ebcb8b   teal    #8fbcbb (rose-slot)
blue10  #5e81ac (pine)    cyan8   #88c0d0 (foam)    blue9   #81a1c1 (iris)
```

Rose Pine → Nord hex map (used consistently across all files):
```
191724→2e3440  1f1d2e→3b4252  26233a→3b4252  403d52→434c5e  6e6a86→4c566a
908caa→d8dee9  e0def4→d8dee9  c4a7e7→81a1c1  ebbcba→8fbcbb  9ccfd8→88c0d0
eb6f92→bf616a  f6c177→ebcb8b  31748f→5e81ac  0f0d1a→232730
```
Decimal `rgba(R,G,B,...)` and macOS `0xffRRGGBB` forms remapped from the same map.

---

## Part 1 — Shared modules (tmux + neovim)

**`modules/home/tmux/`**
- `theme.nix`: remap Rose Pine hexes → Nord (status bar, panes, message, mode).
- `default.nix`: prefix `C-a` → `C-Space`; align binds to the Fedora set
  (`|`/`-` splits, `h/j/k/l` select, `Shift+HJKL` resize, `r` reload, vi copy with
  `wl-copy` on Linux / `pbcopy` on macOS). Keep plugins (sensible, yank, resurrect,
  continuum).
  - **Cross-platform copy:** the yank command differs (Linux `wl-copy`, macOS
    `pbcopy`). Use `reattach-to-user-namespace`/`pbcopy` only on darwin. Handle via
    a `copy_cmd` that's set per-platform (the tmux module takes `pkgs`/platform; pick
    `pbcopy` when `stdenv.isDarwin`, else `wl-copy`).

**`modules/home/neovim/plugins/colorscheme.nix`**
- `programs.nixvim.colorschemes.rose-pine` → `programs.nixvim.colorschemes.nord`
  (nord.nvim, shipped in nixvim). Set `enable = true`. Remove rose-pine block.
- Verify the nixvim option name is `colorschemes.nord` at the pinned nixvim; if the
  module is absent, fall back to `base16` with a Nord palette or `extraPlugins` +
  `colorscheme nord`.

Impact: WSL + VPS also get Nord + `Ctrl+Space`. Accepted.

---

## Part 2 — macOS (nix-darwin) — recolor only

All changes are **color value swaps** (no logic/keybind/package changes).

1. `modules/darwin/sketchybar/default.nix` — `0xffRRGGBB` + bare hex Rose Pine →
   Nord (iris→blue9, foam→cyan8, gold, love→red, text, bg, muted).
2. `modules/home/kitty/default.nix` — `#…` Rose Pine → Nord (same block shape as the
   Fedora kitty colors).
3. `modules/home/ghostty/default.nix` — `#c4a7e7`/`#e0def4`/etc → Nord.
4. `modules/darwin/aerospace/default.nix` — jankyborders `active_color 0xffc4a7e7` →
   `0xff81a1c1`; `inactive_color 0x40403d52` → `0x40434c5e`. Gaps/keybinds unchanged.

tmux + neovim Nord come from the shared modules (Part 1).

**Cannot be tested from Linux.** nix-darwin only evaluates on macOS. Mitigation:
pure value swaps (lowest risk), no structural edits; user applies + verifies on the
Mac. Worst case = one wrong color, cosmetic and trivially fixable.

---

## Part 3 — NixOS workstation — full Hyprland port

Overhaul `modules/home/hyprland/` (nested HM module, twin of `fedora-hyprland`) to
Nord + all Fedora features, adapted.

**Files:**
- `modules/home/hyprland/default.nix` — Nord settings; keybinds: add move
  (`Mod+Shift+arrows`), resize (`Mod+Ctrl+arrows`), maximize (`Mod+Shift+F`); fix
  `Mod+J` (togglesplit → `Mod+T`); binds for screenshot (`Print`), net-menu
  (`Super+N`), volume/brightness via `osd`; exec-once standard (no PATH/NVIDIA hacks).
- `modules/home/hyprland/eww/eww.yuck` + `eww.scss` — port Fedora eww: 12-hour clock
  + AM/PM, clickable date → calendar popup, cpu/ram/disk meters, clickable
  volume(→pavucontrol)/battery(→gnome? see note)/net(→net-menu); Nord colors.
- `modules/home/hyprland/eww.nix` — eww enable (nested).
- `modules/home/hyprland/hypridle.nix` — drop idle auto-suspend; re-open eww on resume.
- `modules/home/hyprland/theme.nix` — GTK Nordic + Nordzy icons + GTK4 css link.
- `modules/home/hyprland/wofi.nix` — keep wofi; add rofi configs (`clip.rasi`,
  `capture.rasi`).
- New `home.file` scripts: `clip-menu`, `net-menu`, `screenshot`, `osd` (nested under
  `home-manager.users.${username}`).
- `modules/home/packages/nixos.nix` — add `wf-recorder`, `rofi`, `nordic`,
  `nordzy-icon-theme`, `cascadia-code`/`nerd-fonts.caskaydia-cove` if not present.

**Adaptation from Fedora (removed/changed):**
- No `wayland.windowManager.hyprland.package = null` — use the NixOS-managed package.
- No NVIDIA Optimus `env` block — omit by default (re-add only if the workstation is
  NVIDIA; see Inputs).
- No `PATH` env hack — NixOS session PATH is correct.
- No systemd services for eww/cliphist + `import-environment` — NixOS Hyprland reaches
  `graphical-session.target`, so plain `exec-once` works (eww open bar, cliphist
  watchers, mako, hypridle).
- Flat → nested: everything wrapped in `home-manager.users.${username}`.

**Battery click:** Fedora used `gnome-control-center` (GNOME present on Fedora). On
NixOS workstation GNOME may not be installed → use a lighter target or omit the
battery onclick. Decision: battery click runs `gnome-control-center power` **only if**
that binary exists, else no-op (guard in a tiny wrapper). Keep it simple — wire to a
power menu later if wanted.

**Font:** use `CaskaydiaCove Nerd Font` (matches Fedora). Ensure font package present.

## Inputs needed (safe defaults if unknown)

1. **Monitor name** — default `monitor = [",preferred,auto,1.0"]` (auto-detect all
   outputs) instead of a hardcoded `eDP-1`. User refines after first boot via
   `hyprctl monitors`.
2. **GPU** — assume non-NVIDIA: no GPU env. If NVIDIA, add the Optimus/cursor env
   (documented in the plan as an optional block).

## Verification

- **Shared + NixOS:** `nix build .#nixosConfigurations.workstation.config.system.build.toplevel`
  (eval + build) catches all Nix/eval errors. Also build `wsl` to confirm the shared
  tmux/neovim change still evaluates.
- **macOS:** cannot eval from Linux. Best effort = visual review of the hex swaps +
  `nix fmt`/syntax sanity; user runs `darwin-rebuild switch` on the Mac.
- **Fedora regression:** `nix build .#homeConfigurations.keycode.activationPackage`
  must still build (shared tmux/neovim changes touch it; Fedora has its own
  hyprland/tmux so the desktop is unaffected, but the shared neovim flatten/colorscheme
  is shared — confirm).

## Risks

- **macOS untestable** — mitigated by recolor-only scope; user verifies.
- **NixOS monitor/GPU** — defaults may need a one-line tweak after first boot.
- **NixOS GUI specifics** (bar position, glyphs, calendar styling) — not visible from
  here; cosmetic, fixable after apply.
- **Shared neovim colorscheme** — nixvim `colorschemes.nord` availability; verified at
  build time.
- **tmux cross-platform copy** — `pbcopy` vs `wl-copy`; guarded by `stdenv.isDarwin`.

## Out of scope
- Refactoring Fedora into a shared single-source (Approach A) — deferred.
- Mac window-manager keybind changes (already match) — none.
- Any app/package additions beyond desktop tools listed above.
