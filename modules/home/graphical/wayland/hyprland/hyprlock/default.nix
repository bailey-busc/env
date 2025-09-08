{
  self,
  osConfig,
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (osConfig.env.theme) fonts;
  inherit (lib) mkIf;
in
{
  programs = mkIf config.wayland.windowManager.hyprland.enable {
    hyprlock = {
      enable = true;
      settings = {
        background = {
          monitor = "";
          path = self.lib.assets.wallpapers.trees;

          blur_passes = 3;
          contrast = 0.8916;
          brightness = 0.8172;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.1;
        };

        general = {
          no_fade_in = false;
          grace = 0;
          disable_loading_bar = true;
        };

        input-field = [
          {
            monitor = "";
            size = "300, 60";
            outline_thickness = 3;
            dots_size = 0.22;
            dots_spacing = 0.2;
            dots_center = true;
            outer_color = "rgba(0, 0, 0, 0)";
            inner_color = "rgba(30, 30, 30, 0.7)";
            font_color = "rgb(230, 230, 230)";
            fade_on_empty = true;
            font_family = fonts.mono.name;

            placeholder_text = "Password";
            hide_input = false;
            position = "0, -120";
            halign = "center";
            valign = "center";
            capslock_color = "rgb(255, 220, 220)";
            numlock_color = "rgb(220, 255, 220)";
            ring_color = "rgb(200, 200, 200)";
            ring_ver_color = "rgb(230, 230, 230)";
          }
        ];

        label = [
          # Clock
          {
            monitor = "";
            text = "cmd[update:1000] echo \"$(date +\"%-I:%M%p\")\"";
            color = "rgb(255, 255, 255)";
            font_size = 120;
            font_family = "${fonts.sans.name} ExtraBold";
            position = "0, -300";
            halign = "center";
            valign = "top";
            shadow_passes = 2;
            shadow_size = 10;
            shadow_color = "rgba(0, 0, 0, 0.5)";
            shadow_boost = 1.2;
          }

          # Date
          {
            monitor = "";
            text = "cmd[update:60000] echo \"$(date +\"%A, %B %d\")\"";
            color = "rgb(200, 200, 200)";
            font_size = 30;
            font_family = fonts.sans.name;
            position = "0, -200";
            halign = "center";
            valign = "top";
          }

          # USER
          {
            monitor = "";
            text = "$USER..?";
            color = "rgb(230, 230, 230)";
            font_size = 28;
            font_family = fonts.sans.name;
            position = "0, -40";
            halign = "center";
            valign = "center";
            shadow_passes = 1;
            shadow_size = 5;
            shadow_color = "rgba(0, 0, 0, 0.3)";
          }
        ];

      };
    };
  };
}
