{ config, pkgs, ... }:
{
  xdg = {
    mime.enable = true;
    mimeApps = {
      enable = true;
      defaultApplications =
        let
          firefox = "firefox-url-handler.desktop";
          okular = "okularApplication_kimgio.desktop";
        in
        {
          "application/json" = "code.desktop";
          "application/pdf" = firefox;
          "application/x-bittorrent" = "transmission-gtk.desktop";
          "audio/flac" = "mpv.desktop";
          "audio/mp3" = "mpv.desktop";
          "audio/ogg" = "mpv.desktop";
          "image/gif" = okular;
          "image/jpeg" = okular;
          "image/png" = okular;
          "image/webp" = okular;
          "inode/directory" = "thunar.desktop";
          "text/html" = firefox;
          "text/plain" = "code.desktop";
          "video/mkv" = "mpv.desktop";
          "video/mp4" = "mpv.desktop";
          "video/webm" = "mpv.desktop";
          "x-scheme-handler/about" = firefox;
          "x-scheme-handler/http" = firefox;
          "x-scheme-handler/https" = firefox;
          "x-scheme-handler/magnet" = "transmission-gtk.desktop";
          "x-scheme-handler/unknown" = firefox;
        };
    };
    # portal = {
    #   # enable = true;
    #   configPackages = [
    #     config.wayland.windowManager.hyprland.finalPackage
    #     pkgs.xdg-desktop-portal-hyprland
    #   ];
    #   extraPortals = with pkgs; [
    #     xdg-desktop-portal-hyprland
    #     xdg-desktop-portal-gtk
    #   ];
    #   xdgOpenUsePortal = true;
    #   config = {
    #     common = {
    #       default = [ "hyprland" ];
    #     };
    #     hyprland = {
    #       default = [
    #         "hyprland"
    #         "*"
    #       ];
    #       "org.freedesktop.impl.portal.Settings" = [ "hyprland" ];
    #       "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
    #       "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
    #       "org.freedesktop.impl.portal.GlobalShortcuts" = [ "hyprland" ];
    #       "org.freedesktop.impl.portal.OpenURI" = [ "*" ];
    #     };
    #   };
    # };
  };
}
