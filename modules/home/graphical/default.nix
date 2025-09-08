{
  pkgs,
  lib,
  config,
  osConfig,
  packages,
  inputs',
  self',
  ...
}:
let
  inherit (lib)
    getExe
    getExe'
    mkIf
    mkMerge
    optionals
    mapAttrs'
    ;
  inherit (pkgs.stdenv) isDarwin isLinux;
  inherit (config.env) profiles;
in
mkIf profiles.graphical.enable {
  services = mkIf isLinux {
    network-manager-applet.enable = mkIf osConfig.networking.networkmanager.enable true;
  };

  home = {
    sessionVariables = mkMerge [
      { ADW_DISABLE_PORTAL = "1"; }
      (mapAttrs'
        (envVarName: color: {
          name = "SHELL_${envVarName}_COLOR";
          value = color;
        })
        (
          with config.scheme.withHashtag;
          {
            SELECTION_BG = base00; # shade- => “black”, de-emphasized/receded background elements, selections, dark UI elements
            BG = base01; # shade => main background colour
            UI_FG = base02; # shade+ => foreground UI elements, rulers, indentation guides and similar
            CONTENT = base03; # sky- => comments, de-emphasized content
            FG = base04; # sky => foreground, code, main content colour, text both in editors and UI elements
            TEXT = base05; # sky+ => emphasized content and emphasized UI text
            BORDER = base06; # sun => selections, light borders, strongly emphasized content
            BORDER_EMPH = base07; # sun+ => “white”, text in highlighted sections, emphasized borders
            RED = red;
            ORANGE = orange;
            YELLOW = yellow;
            GREEN = green;
            CYAN = cyan;
            BLUE = blue;
            PURPLE = base0E;
            MAGENTA = magenta;
          }
        )
      )
    ];

    packages = mkMerge (
      with pkgs;
      [
        [
          drawio
          font-manager
          gparted
          inputs'.icon-browser.packages.default
          kdePackages.ark
          kdePackages.okular
          libnotify
          nomacs
          obsidian
          prusa-slicer
          spotify
          ticktick
          vlc
        ]
        (mkIf profiles.personal.enable [
          # (blender.override {
          #   cudaSupport = osConfig.env.hardware.gpu.nvidia.enable;
          # })
          gimp
          packages.gopro-as-webcam
          inkscape
          shotwell
        ])
        (mkIf osConfig.services.pulseaudio.enable [
          pavucontrol
        ])
        (mkIf osConfig.services.pipewire.enable [
          pwvucontrol
        ])
      ]
    );

    pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      hyprcursor.enable = config.wayland.windowManager.hyprland.enable;
      package = pkgs.phinger-cursors;
      name = "phinger-cursors-dark";
      size = 24;
    };
  };

  programs = {
    rofi = {
      enable = true;
      plugins = with pkgs; [
        rofi-calc
        rofi-file-browser
        rofi-network-manager
        rofi-power-menu
        rofi-screenshot
        rofi-systemd
        rofi-top
      ];
      terminal = getExe config.programs.ghostty.package;
      extraConfig.ssh-client = getExe' osConfig.programs.mosh.package "mosh";
      theme =
        let
          inherit (config.lib.formats.rasi) mkLiteral;
        in
        {
          "*" = {
            font = "${osConfig.env.theme.fonts.widgets.name} 13";

            # macOS Big Sur inspired colors
            bg0 = mkLiteral "rgba(28, 28, 30, 0.85)"; # Main background with transparency
            bg1 = mkLiteral "rgba(44, 44, 46, 0.95)"; # Secondary background
            bg2 = mkLiteral "rgba(58, 58, 60, 0.95)"; # Tertiary background
            bg3 = mkLiteral "rgba(0, 122, 255, 1.0)"; # macOS blue accent

            fg0 = mkLiteral "rgba(255, 255, 255, 0.85)"; # Primary text
            fg1 = mkLiteral "rgba(255, 255, 255, 1.0)"; # Bright text
            fg2 = mkLiteral "rgba(255, 255, 255, 0.55)"; # Secondary text
            fg3 = mkLiteral "rgba(255, 255, 255, 0.25)"; # Disabled text

            border0 = mkLiteral "rgba(255, 255, 255, 0.1)"; # Subtle borders

            background-color = mkLiteral "transparent";
            text-color = mkLiteral "@fg0";

            margin = 0;
            padding = 0;
            spacing = 0;
          };

          window = {
            background-color = mkLiteral "@bg0";
            border = mkLiteral "1px solid";
            border-color = mkLiteral "@border0";
            border-radius = mkLiteral "12px";

            location = mkLiteral "center";
            width = 680;

            # Simulate macOS window shadow
            # box-shadow = mkLiteral "0 10px 40px 0 rgba(0, 0, 0, 0.35)";
            box-shadow = mkLiteral "0 10px 40px 0";
          };

          mainbox = {
            background-color = mkLiteral "transparent";
            border-radius = mkLiteral "12px";
            padding = mkLiteral "1px";
          };

          inputbar = {
            font = "${osConfig.env.theme.fonts.widgets.name} 16";
            background-color = mkLiteral "@bg1";
            text-color = mkLiteral "@fg1";

            margin = mkLiteral "0px";
            padding = mkLiteral "16px 20px";
            spacing = mkLiteral "12px";

            border = mkLiteral "0 0 1px 0";
            border-color = mkLiteral "@border0";
            border-radius = mkLiteral "12px 12px 0 0";

            children = builtins.map mkLiteral [
              "icon-search"
              "entry"
            ];
          };

          icon-search = {
            expand = mkLiteral "false";
            filename = "search";
            size = mkLiteral "20px";
            vertical-align = mkLiteral "0.5";
            text-color = mkLiteral "@fg2";
          };

          "icon-search, entry, element-icon, element-text".vertical-align = mkLiteral "0.5";

          entry = {
            font = mkLiteral "inherit";
            background-color = mkLiteral "transparent";
            text-color = mkLiteral "@fg1";

            placeholder = "Search";
            placeholder-color = mkLiteral "@fg2";

            cursor = mkLiteral "text";
            cursor-color = mkLiteral "@bg3";
            cursor-width = mkLiteral "2px";
          };

          message = {
            margin = mkLiteral "0";
            padding = mkLiteral "12px 20px";
            border = mkLiteral "0 0 1px 0";
            border-color = mkLiteral "@border0";
            background-color = mkLiteral "@bg1";
          };

          textbox = {
            padding = mkLiteral "0";
            background-color = mkLiteral "transparent";
            text-color = mkLiteral "@fg0";
          };

          listview = {
            lines = 8;
            columns = 1;

            background-color = mkLiteral "transparent";
            text-color = mkLiteral "@fg0";

            scrollbar = mkLiteral "false";
            fixed-height = mkLiteral "false";
            fixed-columns = mkLiteral "true";

            margin = mkLiteral "0";
            padding = mkLiteral "8px 0";
            spacing = mkLiteral "2px";
          };

          element = {
            padding = mkLiteral "10px 20px";
            spacing = mkLiteral "12px";
            background-color = mkLiteral "transparent";
            text-color = mkLiteral "@fg0";
            border-radius = mkLiteral "8px";
            cursor = mkLiteral "pointer";
          };

          element-icon = {
            size = mkLiteral "20px";
            background-color = mkLiteral "transparent";
            text-color = mkLiteral "inherit";
          };

          element-text = {
            background-color = mkLiteral "transparent";
            text-color = mkLiteral "inherit";
            highlight = mkLiteral "bold";
          };

          "element normal.normal" = {
            background-color = mkLiteral "transparent";
            text-color = mkLiteral "@fg0";
          };

          "element normal.urgent" = {
            background-color = mkLiteral "transparent";
            text-color = mkLiteral "#FF5F56"; # macOS red
          };

          "element normal.active" = {
            background-color = mkLiteral "transparent";
            text-color = mkLiteral "@bg3";
          };

          "element selected.normal" = {
            background-color = mkLiteral "@bg3";
            text-color = mkLiteral "@fg1";
          };

          "element selected.urgent" = {
            background-color = mkLiteral "#FF5F56";
            text-color = mkLiteral "@fg1";
          };

          "element selected.active" = {
            background-color = mkLiteral "@bg3";
            text-color = mkLiteral "@fg1";
          };

          "element alternate.normal" = {
            background-color = mkLiteral "transparent";
            text-color = mkLiteral "@fg0";
          };

          "element alternate.urgent" = {
            background-color = mkLiteral "transparent";
            text-color = mkLiteral "#FF5F56";
          };

          "element alternate.active" = {
            background-color = mkLiteral "transparent";
            text-color = mkLiteral "@bg3";
          };

          scrollbar = {
            background-color = mkLiteral "@bg1";
            handle-color = mkLiteral "@fg3";
            handle-width = mkLiteral "4px";
            border-radius = mkLiteral "2px";
            margin = mkLiteral "0 4px";
          };

          mode-switcher = {
            enabled = mkLiteral "true";
            background-color = mkLiteral "@bg1";
            text-color = mkLiteral "@fg0";

            border = mkLiteral "1px 0 0 0";
            border-color = mkLiteral "@border0";
            border-radius = mkLiteral "0 0 12px 12px";

            padding = mkLiteral "12px";
            spacing = mkLiteral "8px";
          };

          button = {
            background-color = mkLiteral "transparent";
            text-color = mkLiteral "@fg2";
            padding = mkLiteral "8px 16px";
            border-radius = mkLiteral "6px";
            cursor = mkLiteral "pointer";
          };

          "button selected" = {
            background-color = mkLiteral "@bg3";
            text-color = mkLiteral "@fg1";
          };

          "element normal active".text-color = mkLiteral "@bg2";

          "element alternate active".text-color = mkLiteral "@bg2";

          "element selected normal, element selected active" = {
            background-color = mkLiteral "@bg2";
            text-color = mkLiteral "@fg1";
          };

        };
    };
  };

  gtk = {
    enable = true;
    theme = {
      package = pkgs.whitesur-gtk-theme.override {
        darkerColor = true;
        nautilusStyle = "mojave";
      };
      name = "WhiteSur-Dark-solid";
    };
    iconTheme = {
      name = "WhiteSur-Dark";
      package = pkgs.whitesur-icon-theme.override {
        boldPanelIcons = true;
        alternativeIcons = true;
      };
    };
    font = {
      inherit (osConfig.env.theme.fonts.editor.ui) name package;
      size = 12;
    };
    gtk2.extraConfig = "gtk-application-prefer-dark-theme = true";
    gtk3.extraConfig = config.gtk.gtk4.extraConfig;
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-enable-animations = true;
      gtk-sound-theme-name = "ocean";
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintfull";
    };
  };
  dconf.settings =
    let
      inherit (lib.hm.gvariant) mkTuple;
    in
    {

      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = config.gtk.theme.name;
        icon-theme = config.gtk.iconTheme.name;
      };

      "org/gnome/nautilus/preferences" = {
        default-folder-viewer = "list-view";
        migrated-gtk-settings = true;
        search-filter-time-type = "last_modified";
      };
      "org/gnome/nautilus/window-state" = {
        initial-size = mkTuple [
          890
          550
        ];
        initial-size-file-chooser = mkTuple [
          890
          550
        ];
      };

      "org/gtk/settings/file-chooser" = {
        sort-directories-first = true;
        show-hidden = true;
      };
    };
  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style = {
      name = "whitesur-kde";
      package = pkgs.whitesur-kde;
    };
  };
  programs.obs-studio = {
    enable = profiles.personal.enable;
    package = pkgs.obs-studio.override {
      cudaSupport = osConfig.env.hardware.gpu.nvidia.enable;
    };
    plugins = with pkgs.obs-studio-plugins; [
      advanced-scene-switcher
      input-overlay
      obs-advanced-masks
      obs-backgroundremoval
      obs-composite-blur
      obs-freeze-filter
      obs-gradient-source
      obs-gstreamer
      obs-hyperion
      obs-multi-rtmp
      obs-mute-filter
      obs-pipewire-audio-capture
      obs-source-clone
      obs-source-record
      obs-source-switcher
      obs-teleport
      obs-text-pthread
      obs-vaapi
      obs-vkcapture
      waveform
    ];
  };
  xdg = {
    autostart.enable = false;
    configFile = {
      "gtk-4.0/gtk.css".enable = false;
      "uwsm/env".source = "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
    };
  };
}
