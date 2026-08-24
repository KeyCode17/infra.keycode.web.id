{ ... }:
{
  system.defaults.dock = {
    # AeroSpace keeps all its workspaces on a single native Space. macOS
    # reordering Spaces by recency makes "page N" mean a different page each
    # time and desyncs aerospace's workspace switching from what is on screen.
    mru-spaces = false;

    launchanim = false;
    expose-animation-duration = 0.1;
    autohide = true;
    autohide-delay = 1000.0;
    autohide-time-modifier = 0.0;
    show-recents = false;
    mineffect = "scale";
    minimize-to-application = true;
    tilesize = 1;
    static-only = true;
    persistent-apps = [];
    persistent-others = [];
  };
}
