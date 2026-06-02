{ username, ... }:
{
  security.pam.services.sudo_local.touchIdAuth = true;

  environment.etc."sudoers.d/10-nix-darwin".text = ''
    ${username} ALL=(ALL) NOPASSWD: ALL
  '';

}
