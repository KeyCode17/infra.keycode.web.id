{ username, pkgs, config, ... }:
let
  # Solid Nord base (#2e3440) wallpaper, matching the Fedora desktop (swaybg -c 2e3440).
  wallpaper = pkgs.runCommand "nord-solid-wallpaper" { } ''
    mkdir -p $out
    ${pkgs.imagemagick}/bin/magick -size 2880x1800 xc:'#2e3440' $out/nord-2e3440.png
  '';
  wallpaperPath = "${wallpaper}/nord-2e3440.png";
in
{
  home-manager.users.${username} = { lib, ... }: {
    home.packages = [ wallpaper ];

    home.activation.setWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -f "${wallpaperPath}" ]; then
        /usr/bin/osascript -e 'tell application "System Events" to tell every desktop to set picture to "${wallpaperPath}"'
      fi
    '';
  };
}
