{ username, pkgs, ... }:
{
  home-manager.users.${username}.programs.git = {
    enable = true;
    settings = {
      user.name = "KeyCode17";
      user.email = "m.daffa.karyudi@gmail.com";
      init.defaultBranch = "main";
      push.autoSetupRemote = true;

      # Both hosts authenticate over SSH. Rewriting the https:// forms means
      # pasted web URLs, `go get`, and submodule URLs all resolve to the SSH
      # remote instead of prompting for a username. glab has no
      # `auth git-credential` subcommand, so https + token is not an option
      # for gitlab.com the way it is for github.com.
      url."git@github.com:".insteadOf = "https://github.com/";
      url."git@gitlab.com:".insteadOf = "https://gitlab.com/";

      # Vestigial with the rewrite above, but kept as a safety net for any
      # path that bypasses insteadOf. Referenced via ${pkgs.gh} so it tracks
      # the installed gh rather than pinning a store path that `nix store gc`
      # can collect.
      credential."https://github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
      credential."https://gist.github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
    };
  };
}
