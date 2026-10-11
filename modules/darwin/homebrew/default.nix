{
  config,
  enableLaravel,
  lib,
  ...
}:
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };

    # Mirror the taps nix-homebrew pins, otherwise `cleanup = "zap"` tries to
    # untap them every activation and fails on the read-only nix store paths.
    taps = builtins.attrNames config.nix-homebrew.taps;

    brews = lib.optionals enableLaravel [
      "mysql"
      "postgresql@16"
      "redis"
    ];

    casks = [
      "helium-browser"
      "firefox"
      "google-chrome"
      "discord"
      "slack"
      "pritunl"
      "postman"
      "visual-studio-code"
      "tailscale-app"
      "android-studio"
      "motrix"
    ];
  };
}
