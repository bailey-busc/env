{
  lib,
  config,
  osConfig,
  pkgs,
  packages,
  ...
}@modArgs:
let
  inherit (lib)
    getExe
    getExe'
    concatStringsSep
    flatten
    optionals
    ;
  hyprLib = (import ../lib.nix modArgs);
  inherit (hyprLib)
    mods
    exec
    execSys
    execPkg
    execNamed
    mkBind'
    buttons
    ;

  # Binaries
  firefox' = getExe config.programs.firefox.finalPackage;
  hyprshot' = getExe pkgs.hyprshot;
  terminal' = getExe config.programs.ghostty.package;
  playerctl' = getExe config.services.playerctld.package;
  rofi' = getExe config.programs.rofi.finalPackage;
  rofi-monitor-toggle' = getExe packages.rofi-monitor-toggle;
  waypipe' = getExe pkgs.waypipe;
  wpctl' = getExe' osConfig.services.pipewire.wireplumber.package "wpctl";
  nautilus' = getExe pkgs.nautilus;
  hyprlock' = getExe config.programs.hyprlock.package;
  hyprdrop' = getExe packages.hyprdrop;
  emacsclient' = getExe' config.programs.doom-emacs.finalEmacsPackage "emacsclient";

  isLaptop = osConfig.env.hardware.laptop.enable;

  layoutmsg =
    mods: keys: message:
    mkBind' mods keys "layoutmsg" [ message ];

  # Global modifiers
  meh =
    if isLaptop then
      mods.win
    else
      concatStringsSep " " [
        mods.ctrl
        mods.shift
        mods.alt
      ];
  hyper = concatStringsSep " " [
    meh
    (if isLaptop then mods.alt else mods.win)
  ];
in
{
  config = {
    wayland.windowManager.hyprland.settings = {
      # https://wiki.hypr.land/Configuring/Binds/#bind-flags

      # Binds that bypass app requests to inhibit keybinds
      bindp = [
        (mkBind' [ ] buttons.mouse.sideFront "sendshortcut" [
          mods.alt
          "F10"
          "class:${hyprLib.selectors.classes.legcord}"
        ])
      ];

      # Binds that work when locked + on release
      bindrl = [
        # Mic + volume
        (execSys [ ] buttons.mouse.sideRear "${wpctl'} set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
        (execSys [ ] buttons.media.mute "${wpctl'} set-mute @DEFAULT_AUDIO_SINK@ toggle")
      ];

      # Binds that work when locked + repeat when held
      bindel = [
        (execSys [ ] buttons.media.volumeUp "${wpctl'} set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+")
        (execSys [ ] buttons.media.volumeDown "${wpctl'} set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%-")
      ];

      # Binds that work when locked
      bindl = [
        (execSys hyper "escape" "${rofi'} -modi power-menu:${getExe pkgs.rofi-power-menu} -show power-menu")
        (exec hyper "p" "${hyprshot'} -m region")

        # Media control
        (execSys [ ] buttons.media.play "${playerctl'} play-pause")
        (execSys [ ] buttons.media.prev "${playerctl'} previous")
        (execSys [ ] buttons.media.next "${playerctl'} next")
      ];

      bindr = flatten [
      ];

      bind = flatten [
        # Basics
        (execSys meh "RETURN"
          ''${hyprdrop'} -d -k ghostty ${terminal'} --identifier="${hyprLib.titles.hyprdrop_terminal}"''
        )
        (exec hyper "RETURN" terminal')
        (execSys meh "d" "${rofi'} -show drun -show-icons")
        (execSys hyper "d" "${rofi'} -show run")
        (execSys meh "s" "${rofi'} -show ssh")
        (exec meh "p" <| lib.getExe pkgs.rofi-rbw-wayland)

        (mkBind' hyper "k" "killactive" [ ])
        (mkBind' hyper "s" "togglesplit" [ ])

        (execSys hyper "l" hyprlock')

        # Movement

        (optionals true [
          # (execSys meh "left" "${hyprnome'} -p")
          # (execSys meh "right" hyprnome')
          # (execSys hyper "right" "${hyprnome'} -m")
          # (execSys hyper "left" "${hyprnome'} -m -p")

          (mkBind' meh "up" "prevdesk" [ ])
          (mkBind' meh "down" "nextdesk" [ ])
          (mkBind' hyper "up" "movetoprevdesk" [ ])
          (mkBind' hyper "down" "movetonextdesk" [ ])
        ])
        (optionals true [
          # Move focus between windows
          (layoutmsg meh "left" "focus left")
          (layoutmsg meh "right" "focus right")
          # (layoutmsg meh "up" "focus up")
          # (layoutmsg meh "down" "focus down")

          # Move window in a given direction
          (layoutmsg hyper "left" "movewindowto left")
          (layoutmsg hyper "right" "movewindowto right")
          # (layoutmsg hyper "up" "movewindowto up")
          # (layoutmsg hyper "down" "movewindowto down")

          # Move through the columns
          (layoutmsg meh "mouse_up" "move +col")
          (layoutmsg meh "mouse_down" "move -col")

          # Cycle through column sizes
          (layoutmsg hyper "mouse_up" "colresize +conf")
          (layoutmsg hyper "mouse_down" "colresize -conf")
        ])

        # Apps
        (execNamed meh "b" firefox' "firefox")
        (execNamed meh "f" nautilus' "nautilus")
        (execNamed meh "v" "${emacsclient'} -c" "emacs-client")
        (execPkg meh "z" config.programs.zed-editor.package)

        # Monitors
        (

          builtins.attrValues osConfig.env.displays
          |> builtins.sort (a: b: a.x < b.x)
          |>
            lib.zipListsWith
              (key: display: [
                (mkBind' meh key "focusmonitor" [ display.output ])
                (mkBind' hyper key "movewindow" [ "mon:${display.output}" ])
              ])
              [
                "q"
                "w"
                "e"
                "r"
                "t"
              ]
        )
        (exec meh "m" rofi-monitor-toggle')

        # Remote
        (exec hyper "o" "${waypipe'} ssh orchid Hyprland")

        (mkBind' meh buttons.mouse.middle "movewindow" [ ])
      ];
    };
  };
}
