{ ... }:
{
  system.defaults.CustomUserPreferences = {
    "com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        "64" = { enabled = true; };
        "65" = { enabled = true; };
      };
    };

    "com.apple.Siri" = {
      StatusMenuVisible = false;
      UserHasDeclinedEnable = true;
    };

    "com.apple.gamed" = {
      Disabled = true;
    };

    "com.apple.CrashReporter" = {
      DialogType = "none";
    };

    "com.apple.TimeMachine" = {
      DoNotOfferNewDisksForBackup = true;
    };

    "com.apple.screencapture" = {
      disable-shadow = true;
    };

    "com.apple.SoftwareUpdate" = {
      AutomaticCheckEnabled = false;
      AutomaticDownload = false;
      CriticalUpdateInstall = false;
    };

    "com.apple.LaunchServices" = {
      LSQuarantine = false;
    };

    "com.apple.commerce" = {
      AutoUpdate = false;
    };

    "com.apple.desktopservices" = {
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };

    "NSGlobalDomain" = {
      FocusFollowsMouse = true;
      # Kill window open/close animations
      NSAutomaticWindowAnimationsEnabled = false;
      NSWindowResizeTime = 0.001;
      # Kill scroll animation
      NSScrollAnimationEnabled = false;
      # Prevent macOS from throttling/suspending background apps
      NSAppSleepDisabled = true;
      NSDisableAutomaticTermination = true;
    };

    # NOTE: com.apple.universalaccess is a TCC-protected domain — `defaults write`
    # against it fails ("Could not write domain ...; exiting") during activation
    # unless the activating process has Full Disk Access, which a fresh Mac lacks.
    # Set these by hand in System Settings → Accessibility → Display instead.
    # "com.apple.universalaccess" = {
    #   # Disable transparency — less GPU compositing overhead
    #   reduceTransparency = true;
    #   # Disable motion animations system-wide
    #   reduceMotion = true;
    # };

    "com.apple.finder" = {
      DisableAllAnimations = true;
    };
  };

  system.defaults.NSGlobalDomain = {
    KeyRepeat = 1;
    InitialKeyRepeat = 10;
    _HIHideMenuBar = true;
  };

  # Clean, bare desktop to match the Fedora solid-color desktop: no icons, no widgets.
  system.defaults.finder.CreateDesktop = false;
  system.defaults.WindowManager.StandardHideWidgets = true;
  system.defaults.WindowManager.StageManagerHideWidgets = true;
}
