{
  lib,
  pkgs,
  username,
  enableTilingWM,
  ...
}:
{
  imports = [
    ./base.nix
    ../modules/nixos/android.nix
  ];

  users.users.${username}.extraGroups = [
    "wheel"
    "networkmanager"
    "docker"
    "audio"
    "video"
  ];

  networking.networkmanager.enable = true;

  networking.firewall.enable = true;

  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      tapping = true;
    };
  };

  services.displayManager.ly = {
    enable = true;
    settings = {
      animation = "matrix";
      hide_borders = true;
      clock = "%H:%M";
    };
  };
  services.displayManager.defaultSession = lib.mkIf enableTilingWM "hyprland";

  programs.hyprland = lib.mkIf enableTilingWM {
    enable = true;
    xwayland.enable = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  xdg.portal = {
    enable = true;
    extraPortals =
      with pkgs;
      [
        xdg-desktop-portal-gtk
      ]
      ++ lib.optionals enableTilingWM [
        xdg-desktop-portal-hyprland
      ];
  };

  programs.dconf.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      curl
      libgcc
    ];
  };

  programs = {
    firefox.enable = true;
    git = {
      enable = true;
      lfs.enable = true;
    };
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  services.printing.enable = true;

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.hack
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ];
    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "JetBrainsMono Nerd Font" ];
      };
    };
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
  };

  boot.kernelParams = [
    "i2c_hid.polling_mode=1"
  ];

  services.udev.extraRules = ''
    # ASUP1303 touchpad firmware locks up if power-gated during suspend.
    # Keep i2c device fully powered to prevent the firmware bug.
    SUBSYSTEM=="i2c", KERNEL=="i2c-ASUP1303:00", ATTR{device/power/control}="on"
    ACTION=="add", SUBSYSTEM=="platform", KERNEL=="AMDI0010:03", ATTR{power/control}="on"
  '';

  systemd.services.touchpad-resume-fix = {
    description = "Reset I2C touchpad after resume (workaround for ASUP1303 firmware)";
    wantedBy = [
      "post-resume.target"
      "suspend.target"
    ];
    after = [ "post-resume.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "touchpad-resume-fix" ''
        DRV=/sys/bus/platform/drivers/i2c_designware
        DEV=AMDI0010:03
        if [ -e "$DRV/$DEV" ]; then
          echo "$DEV" > "$DRV/unbind" || true
          sleep 2
          echo "$DEV" > "$DRV/bind" || true
        fi
      '';
    };
  };

  security.polkit.enable = true;

  environment.systemPackages =
    with pkgs;
    [
      wget
      curl
      unzip
      zip
      htop
      btop
      fastfetch
      gcc
      gnumake
      cmake
      nautilus
      libnotify
      polkit_gnome
    ]
    ++ lib.optionals enableTilingWM [
      hyprpaper
      hyprlock
      hypridle
      hyprpicker
      grim
      slurp
      wl-clipboard
      cliphist
      mako
    ];
}
