{
  config,
  lib,
  pkgs,
  inputs',
  ...
}:
let
  inherit (lib)
    getExe
    getExe'
    ;

  inherit (lib.cli) toGNUCommandLine;
in
lib.mkIf config.env.profiles.graphical.enable {
  environment = {
    variables = {
      MOZ_ENABLE_WAYLAND = "1";
      # WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONE_WL = "1";
    };
  };

  programs = {
    xwayland.enable = true;
    uwsm.enable = config.programs.hyprland.withUWSM;
    hyprland = rec {
      enable = true;
      # package = inputs'.hyprland.packages.hyprland.override {
      #   inherit (inputs'.nixpkgs-unstable.legacyPackages) libinput;
      # };
      # portalPackage = inputs'.hyprland.packages.xdg-desktop-portal-hyprland.override {
      #   hyprland = package;
      # };
      withUWSM = true;
      xwayland.enable = true;
      systemd.setPath.enable = true;
    };
    # regreet = {
    #   enable = true;
    #   inherit
    #     theme
    #     iconTheme
    #     font
    #     ;
    #   cursorTheme = {
    #     inherit (cursorTheme) name package;
    #   };
    #   settings = {
    #     background.path = self.lib.assets.wallpapers.nix-black;
    #     background.fit = "Contain";
    #     env = { };
    #     GTK.application_prefer_dark_theme = true;
    #     appearance.greeting_msg = "${lib.toSentenceCase config.env.username}..?";
    #     "widget.clock" = {
    #       format = "%a %H:%M";
    #       timezone = config.time.timeZone;
    #       label_width = 150;
    #     };
    #   };
    # };
  };
  services = {
    # hypridle.enable = true;
    greetd = {
      enable = true;
      settings =
        let
          default_command = "dbus-run-session ${
            pkgs.writeShellScript "hyprland-session-exec"
            <| builtins.concatStringsSep " "
            <| lib.flatten [
              (getExe' config.systemd.package "systemd-run")
              (toGNUCommandLine { } {
                scope = true;
                slice = "compositor.slice";
                description = "Hyprland Session";
              })
              (getExe config.programs.hyprland.package)
            ]
          }";
        in
        {
          # useTextGreeter = true;
          default_session = {
            command = ''
              ${getExe pkgs.greetd.tuigreet} \
                --cmd "${default_command}" \
                --sessions "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions" \
                --theme 'container=black;text=white;greet=brightmagenta;border=brightmagenta;prompt=green;input=magenta;time=cyan;action=yellow;button=magenta'
                --greeting "Welcome to NixOS" \
                --time \
                --remember \nnnnnnnnnnnnnnnnnnnnnnn
                --asterisks
            '';
            user = "greeter";
          };
          initial_session = {
            command = default_command;
            user = config.env.username;
          };
        };
    };
  };
}
