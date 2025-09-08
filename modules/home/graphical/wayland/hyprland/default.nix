{
  config,
  inputs,
  inputs',
  lib,
  osConfig,
  packages,
  pkgs,
  self,
  ...
}@modArgs:
let
  inherit (lib)
    getExe
    getExe'
    optionals
    mkIf
    flatten
    mapAttrsToList
    ;
  inherit (self.lib.modules) enabled;
  inherit (config.env) profiles;
  inherit (pkgs.stdenv) isLinux;
  hyprLib = (import ./lib.nix modArgs);

  workspaces = [
    "work"
    "home"
    "audio"
    "social"
    "games"
  ];
  preTarget = "graphical-session-pre.target";
  graphicalTarget =
    if config.wayland.windowManager.hyprland.systemd.enable then
      "hyprland-session.target"
    else
      config.wayland.systemd.target;

  # Binaries
  hyprctl' = getExe' osConfig.programs.hyprland.package "hyprctl";
  hyprland' = getExe osConfig.programs.hyprland.package;
  hyprlock' = getExe config.programs.hyprlock.package;
  systemctl' = getExe' osConfig.systemd.package "systemctl";
in
{
  imports = [
    inputs.hyprland.homeManagerModules.default
  ];
  config = mkIf (profiles.graphical.enable && isLinux) {
    programs.rofi.extraConfig = {
      run-command = "{cmd}";
      ssh-command = "{terminal} -e {ssh-client} {host}";
      run-shell-command = "{terminal} -e {cmd}";
    };

    wayland.windowManager.hyprland = {
      enable = true;
      # https://wiki.hypr.land/Nix/Hyprland-on-Home-Manager/#using-the-home-manager-module-with-nixos
      package = lib.mkForce null;
      portalPackage = lib.mkForce null;
      systemd = {
        enable = true;
        enableXdgAutostart = false;
        variables = [ "--all" ];
      };
      xwayland.enable = true;
      plugins = with inputs'.hyprland-plugins.packages; [
        hyprbars
        hyprwinwrap
        xtra-dispatchers
        hyprscrolling
        pkgs.hyprhook
        (inputs'.hyprland-virtual-desktops.packages.default.override {
          hyprland = osConfig.programs.hyprland.package;
        })
      ];
      settings = {
        env = [ "XDG_CURRENT_DESKTOP=Hyprland" ];
        plugin = {
          hyprwinwrap.class = hyprLib.selectors.classes.hyprwinwrap;
          hyprhook = {
            # onSubmap = toString <| pkgs.callPackage ./scripts/hyprhook-which-key.nix { };
          };
          hyprscrolling = {
            fullscreen_on_one_column = true;
            column_width = 0.5;
            explicit_column_widths = "0.333, 0.5, 0.677, 1.0";
            focus_fit_method = 0;
            follow_focus = true;
          };
          hyprbars = {
            # TODO: Match MacOS theme
            bar_color = "rgb(${config.scheme.base00})";
            bar_height = 30;

            # bar_blur = true;
            "col.text" = "rgb(${config.scheme.base04})";
            bar_text_size = 14;
            bar_text_font = osConfig.env.theme.fonts.editor.ui.name;

            hyprbars-button = [
              "rgb(${config.scheme.red}), 15, 󰖭, ${hyprctl'} dispatch forcekillactive"
              "rgb(${config.scheme.yellow}), 15, , ${hyprctl'} dispatch killactive"
              "rgb(${config.scheme.green}), 15, , ${hyprctl'} dispatch fullscreen 1"
            ];
            on_double_click = "${hyprctl'} dispatch fullscreen 1";
          };
          virtual-desktops = {
            names = workspaces |> lib.imap1 (n: name: "${toString n}:${name}") |> lib.concatStringsSep ", ";
            cycleworkspaces = 1;
            rememberlayout = "size";
            notifyinit = 0;
            verbose_logging = 0;
          };
        };

        monitorv2 =
          osConfig.env.displays
          |> builtins.attrValues
          |> builtins.sort (a: b: a.x < b.x)
          |> map (d: {
            inherit (d) output;
            mode = "${toString d.width}x${toString d.height}@${toString d.refresh}";
            position = "${toString d.x}x${toString d.y}";
            scale = toString d.scale;
          });

        general = {
          # layout = "dwindle";
          layout = "scrolling";
          resize_on_border = true;

          border_size = 1; # Thin borders like macOS
          gaps_in = 6; # macOS-style window spacing
          gaps_out = 12; # Generous outer gaps for clean look

          extend_border_grab_area = 10; # Subtle grab area
          hover_icon_on_border = false; # Clean macOS-style borders
        };
        xwayland.force_zero_scaling = true;
        # Cursor and focus behavior
        cursor = {
          no_warps = false;
          inactive_timeout = 30; # Hide cursor after 5 seconds of inactivity
        };

        animations = {
          enabled = true;
          bezier = [
            "macOS, 0.25, 0.46, 0.45, 0.94" # Apple's standard easing
            "smoothSpring, 0.42, 0, 0.58, 1" # Smooth spring animation
            "gentleOut, 0.4, 0, 0.2, 1" # Gentle deceleration
            "quickIn, 0.11, 0, 0.5, 0" # Quick start
            "workspaceSwitch, 0.22, 1, 0.36, 1" # Smooth workspace transitions
          ];

          animation = [
            # Window animations - macOS-style smooth and subtle
            "windows, 1, 6, macOS"
            "windowsIn, 1, 6, macOS, popin 85%"
            "windowsOut, 1, 5, smoothSpring, popin 85%"
            "windowsMove, 1, 5, macOS"

            # Border animations - subtle like macOS
            "border, 1, 10, default"
            "borderangle, 1, 8, default"

            # Fade animations - smooth transitions
            "fade, 1, 4, smoothSpring"
            "fadeDim, 1, 4, smoothSpring"
            "fadeIn, 1, 4, smoothSpring"
            "fadeOut, 1, 4, smoothSpring"

            # Workspace animations - smooth like Mission Control
            "workspaces, 1, 5, workspaceSwitch, slide"
            "specialWorkspace, 1, 5, macOS, slidevert"
          ];
        };
        decoration = {
          rounding = 10; # macOS Big Sur window corners

          # Window blur - macOS-style vibrancy
          blur = {
            enabled = true;
            size = 20; # Strong blur like macOS
            passes = 3; # Multiple passes for quality
            new_optimizations = true; # Performance optimizations
            xray = false; # Don't see through all windows
            ignore_opacity = true; # Respect window opacity settings
            noise = 0.02; # Subtle noise texture
            contrast = 1.1; # Slight contrast boost
            brightness = 1.0; # Neutral brightness
            vibrancy = 0.15; # Subtle vibrancy effect
          };

          shadow = {
            enabled = true;
            # macOS-style shadows
            range = 30; # Larger, softer shadows
            render_power = 3; # Subtle intensity
            offset = "0 8"; # Vertical offset like macOS
            scale = 0.98; # Natural scale
            ignore_window = true; # Don't apply shadow to window itself
            color = "rgba(0, 0, 0, 0.35)"; # Semi-transparent black
          };

          # Active/inactive window appearance
          active_opacity = 1.0; # Full opacity for active windows
          inactive_opacity = 0.97; # Very subtle transparency
          fullscreen_opacity = 1.0; # Full opacity for fullscreen windows

          # Dimming
          dim_inactive = true; # Dim inactive windows like macOS
          dim_strength = 0.05; # Very subtle dimming
          dim_special = 0.2; # Dimming for special workspace
        };
        input = {
          kb_layout = "us";
          kb_options = "caps:ctrl_modifier";
          follow_mouse = 1;
          float_switch_override_focus = 2;
          numlock_by_default = true;
        };
        binds = {
          allow_workspace_cycles = true;
          drag_threshold = 10;
        };
        windowrulev2 = flatten [
          # Bitwig
          "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
          # "size 80% 80%,title:${hyprLib.selectors.apps.vital.title}"
          "tile,title:${hyprLib.selectors.apps.vital.title}"

          # Signal - slightly transparent with blur for depth
          "opacity 0.92 0.92,title:^([Ss]ignal)"

          # Steam
          "stayfocused, initialtitle:${hyprLib.selectors.titles.empty}, initialclass:${hyprLib.selectors.classes.steam}"
          "minsize 1 1, initialtitle:${hyprLib.selectors.titles.empty}, initialclass:${hyprLib.selectors.classes.steam}"
          "maximize, initialtitle:^(\S+)$, initialclass:^(steamwebhelper)$"
          "immediate, initialclass:${hyprLib.selectors.classes.steamGames}"
          "fullscreen, initialclass:${hyprLib.selectors.classes.steamGames}"

          # File picker
          "float, class:^(Show-file-dialog-gtk3)"
          "center, class:^(Show-file-dialog-gtk3)"
          "animation windowsIn:popin, class:^(Show-file-dialog-gtk3)" # Pop-in animation

          # Input handling
          "prop allowsinput, class:${hyprLib.selectors.classes.eve}"
          "prop allowsinput, class:${hyprLib.selectors.classes.legcord}"

          # Hyprdrop - styled terminal windows
          "float, title:${hyprLib.selectors.titles.hyprdrop_terminal}"
          "center, title:${hyprLib.selectors.titles.hyprdrop_terminal}"
          "size 80% 70%, title:${hyprLib.selectors.titles.hyprdrop_terminal}"
          "opacity 0.95 0.95, title:${hyprLib.selectors.titles.hyprdrop_terminal}" # Slight transparency
          "animation windowsIn:popin, title:${hyprLib.selectors.titles.hyprdrop_terminal}" # Pop-in animation
          # "bordercolor rgba(255, 255, 255, 0.8), title:${hyprLib.selectors.titles.hyprdrop_terminal}" # Custom border

          # Bottom system monitor
          "float, class:${hyprLib.selectors.classes.bottom}"
          "center, class:${hyprLib.selectors.classes.bottom}"
          "size 60% 20%, class:${hyprLib.selectors.classes.bottom}"
          "opacity 0.95 0.95, class:${hyprLib.selectors.classes.bottom}"
          "bordercolor rgba(200, 200, 200, 0.8), class:${hyprLib.selectors.classes.bottom}" # Custom border

          # Barz
          "plugin:hyprbars:nobar,floating:0"
          "plugin:hyprbars:nobar,title:${hyprLib.selectors.titles.hyprdrop_terminal}"

          # Slack debugging - full opacity for readability
          "opacity 1.0 override,class:${hyprLib.selectors.classes.slack}"
          "prop noblur,class:${hyprLib.selectors.classes.slack}"
          "prop noshadow,class:${hyprLib.selectors.classes.slack}"
          # "bordercolor rgba(255, 255, 255, 0.8),class:${hyprLib.selectors.classes.slack}" # Custom border

          (optionals (config.systemd.user.services ? xwaylandvideobridge) [
            # xwayland sharing
            "opacity 0.0 override,class:${hyprLib.selectors.classes.xwaylandvideobridge}"
            "prop noanim,class:${hyprLib.selectors.classes.xwaylandvideobridge}"
            "noinitialfocus,class:${hyprLib.selectors.classes.xwaylandvideobridge}"
            "maxsize 1 1,class:${hyprLib.selectors.classes.xwaylandvideobridge}"
            "prop noblur,class:${hyprLib.selectors.classes.xwaylandvideobridge}"
          ])

          (map (e: "opacity 0.95 0.95,title:^(${e}.*)") [
            "Waypaper"
            "Visual Studio Code"
            "G.*I.*M.*P"
            #"[Ff]irefox"
            #"Slack"
          ])
        ];
        # Enhanced workspace management for multi-monitor setup
        workspace = [
          # # Primary monitor workspaces (1-5)
          # "1, monitor:eDP-1, default:true, persistent:true"
          # "2, monitor:eDP-1, persistent:true"
          # "3, monitor:eDP-1, persistent:true"
          # "4, monitor:eDP-1, persistent:true"
          # "5, monitor:eDP-1, persistent:true"

          # # Secondary monitor workspaces (6-10) if available
          # "6, monitor:HDMI-A-1, persistent:true"
          # "7, monitor:HDMI-A-1, persistent:true"
          # "8, monitor:HDMI-A-1, persistent:true"
          # "9, monitor:HDMI-A-1, persistent:true"
          # "10, monitor:HDMI-A-1, persistent:true"

          # Special workspaces
          "special:files, on-created-empty:${getExe pkgs.nautilus}"
        ];
        gestures = {
          workspace_swipe = true;
          workspace_swipe_forever = true;
        };
        exec-once = [
          hyprlock'
          # "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        ];
        misc = {
          disable_splash_rendering = true;
          disable_hyprland_logo = true;

          #animate_manual_resizes = true; # Smooth animations when manually resizing
          #animate_mouse_windowdragging = true; # Smooth animations when dragging windows

          # Focus behavior
          focus_on_activate = true; # Windows demanding attention will receive focus

          # Visual feedback
          #render_ahead_of_time = true; # Smoother animations
          #render_ahead_safezone = 1; # Balance between smoothness and latency

          # Mouse behavior
          mouse_move_enables_dpms = true; # Wake display on mouse movement
          key_press_enables_dpms = true; # Wake display on key press

          # # Performance settings
          # vfr = true; # Variable refresh rate for power efficiency
          # vrr = 1; # Variable refresh rate mode
        };
      };
    };
    home = {
      sessionVariables = lib.genAttrs [
        "SLACK_USE_WAYLAND"
        "SLACK_DISABLE_GPU_SANDBOX"
        "MOZ_DBUS_REMOTE"
        "MOZ_ENABLE_WAYLAND"
      ] (_: "1");

      packages = with pkgs; [
        hyprpicker
        hyprdim
        hyprkeys
        grimblast
        grim
        swww
        upower
        wdisplays
        slurp
        nautilus
        packages.rofi-monitor-toggle
      ];

      file.".config/xkb/custom".source = pkgs.writeText "custom" ''
        xkb_symbols "basic" {
          include "pc+us"

          replace key <CAPS> {
            [ Hyper_L, Hyper_L ]
          };

          modifier_map Mod3 { Hyper_L };
        };
      '';
    };

    services = {
      hyprpaper = {
        enable = true;
        settings =
          let
            displayWallpapers =
              osConfig.env.displays
              |> builtins.attrValues
              |> map (d: "${d.output}, ${pkgs.mkNixLogoWallpaper { inherit (d) width height; }}");
          in
          {
            ipc = true;
            splash = false;
            preload = builtins.attrValues self.lib.assets.wallpapers ++ displayWallpapers;
            reload = displayWallpapers;
            wallpaper = displayWallpapers;
          };
      };
      hyprsunset = {
        enable = false;
        transitions = {
          sunrise = {
            calendar = "*-*-* 05:30:00";
            requests = [
              [ "temperature 6500" ]
              [ "identity" ]
            ];
          };
          sunset = {
            calendar = "*-*-* 22:00:00";
            requests = [ [ "temperature 4500" ] ];
          };
        };
      };
      hyprpolkitagent = enabled;
    };

  };
}
