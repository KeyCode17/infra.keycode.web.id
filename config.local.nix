{
  darwinUsername = "keycode";
  darwinHostname = "keycode-mac";
  darwinEnableTilingWM = true;

  fedoraUsername = "keycode";
  fedoraHostname = "fedora";

  enableLaravel = false;
  enableRust = true;
  enableVolta = true;
  enableGolang = false;

  sshKeys = [
    # TODO: replace with YOUR Mac public key -> run: cat ~/.ssh/id_ed25519.pub
    "ssh-ed25519 AAAAREPLACE_ME keycode@keycode-mac"
  ];
}
