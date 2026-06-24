{
  pkgs,
  username,
  ...
}:
{
  home-manager.users.${username} = {
    gtk = {
      enable = true;

      theme = {
        name = "Nordic";
        package = pkgs.nordic;
      };

      iconTheme = {
        name = "Nordzy";
        package = pkgs.nordzy-icon-theme;
      };

      cursorTheme = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        size = 32;
      };

      font = {
        name = "Quicksand";
        size = 11;
      };

      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-decoration-layout = "appmenu:none";
      };

      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-decoration-layout = "appmenu:none";
      };
    };

    qt = {
      enable = true;
      platformTheme.name = "gtk";
      style = {
        name = "kvantum";
      };
    };

    home.packages = with pkgs; [
      libsForQt5.qtstyleplugin-kvantum
      kdePackages.qtstyleplugin-kvantum
      nordic
      adw-gtk3
    ];

    xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=Nordic
    '';

    home.pointerCursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 32;
      gtk.enable = true;
      x11.enable = true;
    };

    home.sessionVariables = {
      XCURSOR_SIZE = "32";
      XCURSOR_THEME = "Bibata-Modern-Classic";
      GTK_THEME = "Nordic:dark";
    };

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "Nordic";
        icon-theme = "Nordzy";
        cursor-theme = "Bibata-Modern-Classic";
        font-name = "Quicksand 11";
        document-font-name = "Quicksand 11";
        monospace-font-name = "JetBrainsMono Nerd Font 11";
      };
    };

    # TODO: Add wallpaper.jpg to repo root to enable this
    # home.file.".config/hypr/wallpaper.jpg".source = ../../../wallpaper.jpg;
  };
}
