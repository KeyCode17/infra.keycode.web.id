{ username, ... }:
{
  nix.enable = false;
  determinate-nix.customSettings = {
    eval-cores = 0;
    download-buffer-size = 134217728; # 128 MiB
    extra-experimental-features = [
      "build-time-fetch-tree"
      "parallel-eval"
    ];

    # Store maintenance — Determinate ships these disabled, so nothing was
    # deduplicating or freeing the store. Hardlink identical paths and keep the
    # GC in a 10-50 GiB band. (adapted from upstream perf(darwin) store maintenance)
    auto-optimise-store = true;
    min-free = 10737418240; # 10 GiB
    max-free = 53687091200; # 50 GiB

    # Concurrency — tuned for this 24 GB / 10-core (4P+6E) Mac. Determinate's
    # defaults (max-jobs ~ one-per-core, cores = 0 unlimited) oversubscribe RAM
    # and spill compile threads onto the slow E-cores. (adapted from upstream)
    max-jobs = 6;
    cores = 2;
    max-substitution-jobs = 32; # fetching is I/O-bound and cheap in memory
    http-connections = 50;
    keep-going = true;
    warn-dirty = false;

    # Fail over from an unreachable substituter in 5s instead of stalling, and
    # make this user trusted so flake substituters/settings actually apply
    # (otherwise clan needs --option accept-flake-config true).
    connect-timeout = 5;
    trusted-users = [
      "root"
      username
    ];
  };

  # Weekly store GC. nix.gc.* is guarded by nix.enable — which Determinate turns
  # off — so it never runs; a launchd daemon is the only thing that fires.
  launchd.daemons.nix-gc = {
    serviceConfig = {
      Label = "org.nixos.nix-gc";
      ProgramArguments = [
        "/nix/var/nix/profiles/default/bin/nix-collect-garbage"
        "--delete-older-than"
        "30d"
      ];
      StartCalendarInterval = [
        {
          Weekday = 0;
          Hour = 4;
          Minute = 0;
        }
      ];
      RunAtLoad = false;
      LowPriorityIO = true;
      Nice = 10;
      StandardOutPath = "/var/log/nix-gc.log";
      StandardErrorPath = "/var/log/nix-gc.log";
    };
  };
}
