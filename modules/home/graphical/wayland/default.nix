{
  pkgs,
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib) getExe mkIf mkForce;
  inherit (self.lib) genAttrs';
  inherit (pkgs.stdenv) isLinux;

  waylandTarget = config.wayland.systemd.target;
in
mkIf (config.env.profiles.graphical.enable && isLinux) {
  home = {
    packages = with pkgs; [
      waypaper
      kdePackages.xwaylandvideobridge
      wl-clipboard
      wev
      waypipe
    ];
    sessionVariables = {
      GSK_RENDERER = "ngl";
      MOZ_DBUS_REMOTE = "1";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      SDL_VIDEODRIVER = "wayland";
      WEBKIT_DISABLE_DMABUF_RENDERER = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
      XDG_SESSION_TYPE = "wayland";
      _JAVA_AWT_WM_NONREPARENTING = "1";
    };
  };

  programs.rofi = {
    package = mkForce pkgs.rofi-wayland;
    plugins = with pkgs; [
      rofi-emoji-wayland
      rofi-pass-wayland
      rofi-rbw-wayland
    ];
  };

  xdg.configFile =
    [
      "chrome"
      "chromium"
      "electron"
      "slack"
      "spotify"
      "vscode"
    ]
    |> map (app: "${app}-flags.conf")
    |> genAttrs' (_: {
      text = "--ozone-platform-hint=auto";
    });

  systemd.user.services.xwaylandvideobridge = {
    Unit = {
      Description = "Tool to make it easy to stream wayland windows and screens to existing applications running under Xwayland";

      After = [ waylandTarget ];
      PartOf = [ waylandTarget ];
      Requires = [ waylandTarget ];
    };
    Service = {
      Type = "simple";

      ExecStart = getExe pkgs.kdePackages.xwaylandvideobridge;
      Restart = "on-failure";
    };
    Install.WantedBy = [ waylandTarget ];
  };
}
