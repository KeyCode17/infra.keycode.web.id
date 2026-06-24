# Setup Mac (nix-darwin) — instructions for Claude Code

This repo configures a Mac via **nix-darwin + Clan**. The darwin machine is
`keycode-mac`, user `keycode`. Repo lives at `~/.config/nix` on the Mac.

If you are Claude Code running on the Mac: execute the steps below, fixing any
error as it comes up until the rebuild succeeds. Ask the user only for the
manual prerequisites (sudo install, Remote Login) and for the SSH key if one
must be generated.

---

## Manual prerequisites (user does these — Claude can run the commands but they need sudo / GUI)

1. **Install Determinate Nix** (this flake needs Determinate Nix, not vanilla):
   ```sh
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```
   Restart the shell afterwards so `nix` is on PATH.

2. **Enable Remote Login** (Clan's `targetHost = keycode@localhost` needs it):
   System Settings → General → Sharing → **Remote Login = On**.
   (Only required if deploying via `clan machines update`. Plain
   `darwin-rebuild`/`nix run nix-darwin` does NOT need it.)

---

## Steps

### 1. Clone the repo
```sh
git clone https://github.com/KeyCode17/infra.keycode.web.id ~/.config/nix
cd ~/.config/nix
```
(If it already exists: `cd ~/.config/nix && git pull`.)

### 2. Fix identity in `config.local.nix`
```sh
whoami   # the real macOS account short name
```
Open `~/.config/nix/config.local.nix`:
- `darwinUsername` **must equal** the `whoami` output. If your account isn't
  `keycode`, change it (home-manager manages `/Users/<darwinUsername>`).
- `darwinHostname = "keycode-mac"` — the Clan machine name / flake attr. Keep it
  unless you want a different name (then also rebuild with that name).

### 3. SSH key
```sh
cat ~/.ssh/id_ed25519.pub   # if this fails, generate one:
ssh-keygen -t ed25519 -C "m.daffa.karyudi@gmail.com"
```
Put the `.pub` line into the `sshKeys = [ ... ];` list in `config.local.nix`,
replacing the placeholder `"ssh-ed25519 AAAAREPLACE_ME keycode@keycode-mac"`.

### 4. First build (bootstrap)
`darwin-rebuild` isn't installed yet, so the FIRST switch must go through
`nix run`:
```sh
sudo nix run nix-darwin -- switch --flake ~/.config/nix#keycode-mac
```
- nix-homebrew clones the homebrew taps on first run — this is slow, be patient.
- Fix any eval/build error and re-run until it succeeds.

### 5. Subsequent rebuilds
After the first success, `darwin-rebuild` is on PATH. Use the alias:
```sh
build-system        # = sudo nix run nix-darwin -- switch --flake ~/.config/nix
# or explicitly:
darwin-rebuild switch --flake ~/.config/nix#keycode-mac
```

---

## Verify after a successful switch
- **aerospace** tiling WM running (`Alt+Enter` opens kitty; `Alt+hjkl` focus).
- **sketchybar** top bar visible, Nord-colored.
- **kitty / ghostty** terminals open with the Nord palette.
- **tmux**: prefix is `Ctrl+Space`; `|`/`-` split, `h/j/k/l` select panes,
  `y` in copy-mode yanks to the macOS clipboard (pbcopy).
- **neovim** (`v` / `nvim`) uses the Nord colorscheme.
- **aliases**: `gs`, `ll`, `lazygit`, `lazydocker`, `build-system` all work.
- **git identity**: `git config user.name` → `KeyCode17`.

## Notes / gotchas
- First switch **must** be `nix run nix-darwin -- switch` — `darwin-rebuild`
  doesn't exist yet.
- The flake is Determinate-based (`nix.enable = false`,
  `determinate-nix.customSettings` in `modules/nix.nix`). Vanilla Nix will fail.
- Tiling WM is gated by `darwinEnableTilingWM = true` in `config.local.nix`.
- `meta.name`/`meta.domain` are `keycode` / `keycode.web.id`.
- Only two machines exist in this repo: `keycode-mac` (this Mac) and the Fedora
  home-manager config (`homeConfigurations.keycode`). The old msdqn machines
  (workstation/wsl/VPS/android) were removed.
