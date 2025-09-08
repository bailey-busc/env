# Define the entire Hyprland config system as a Nix DSL (Dick Sucking Language)
{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    checkListOfEnum
    concatStringsSep
    getExe
    id
    isDerivation
    optionalString
    optional
    toList
    toUpper
    getExe'
    ;

  isPackage = isDerivation;
  mkValidator =
    {
      options,
      message ? "value invalid",
      transform ? id,
      nullable ? true,
    }:
    original:
    let
      valid = options ++ optional nullable null;
      given = original |> toList |> map transform;
      validationResult = checkListOfEnum message valid given; # type: a -> a
    in
    validationResult original;

  # Modifiers as recognized by Hyprland:
  mods = {
    alt = "ALT";
    capslock = "CAPS";
    ctrl = "CONTROL";
    mod2 = "MOD2";
    mod3 = "MOD3";
    mod5 = "MOD5";
    shift = "SHIFT";
    win = "SUPER";
  };

  validateMod = mkValidator {
    message = "modifier invalid";
    transform = toUpper;
    options = builtins.attrValues mods;
    nullable = false;
  };

  parameters = {
    window =
      {
        class ? null,
        title ? null,
        initialClass ? null,
        initialTitle ? null,
        tag ? null,
        xwayland ? null,
        floating ? null, # bool
        fullscreen ? null, # bool
        pid ? null, # Number
        address ? null,
        activeWindow ? null, # bool
        tiled ? null, # bool
      }:
      "";
  };
  titles = rec {
    hyprdrop_terminal = hyprdrop_ghostty;
    hyprdrop_ghostty = "hyprdrop_ghostty";
  };
  classes = rec {
    bottom = "bottom_hyprdrop";
    xwaylandvideobridge = "xwaylandvideobridge";
    slack = "Slack";
    firefox = "firefox";
    browser = firefox;
    legcord = "legcord";
    steam = "steam";
  };
  selectors = {
    apps = {
      zellij = {
        class = "^(kitty)$";
        title = "^(Zellij.*)$";
      };
      vital = {
        title = "^(Vital.*)$";
      };
      firefoxSaveFileModal = {
        class = "^(firefox)$";
        title = "^(Save As.*)$";
      };
    };
    titles = lib.mergeAttrsList [
      (lib.mapAttrs (_: title: "^(${title})$") titles)
      {
        empty = "^()$";
      }
    ];

    classes = lib.mergeAttrsList [
      (lib.mapAttrs (_: class: "^(${class})$") classes)
      rec {
        terminal = ghostty;
        empty = "^()$";
        ghostty = "^(com\.mitchellh\.ghostty)$";
        eve = "^(steam_app_8500)$";
        steamGames = "^(steam_app_\d+)$";
        fileManager = "^(org\.gnome\.Nautilus)$";
        editor = zed;
        zed = "^(dev\.zed\.Zed-Preview)$";
        imageBrowser = "^(org\.nomacs.ImageLounge)$";
        bitwig = "^(com\.bitwig\.BitwigStudio?)$";
        hyprwinwrap = "^(hyprwinwrap-bg)$";
        obs = "^(com\.obsproject\.Studio)$";
      }
    ];
  };
  buttons = {
    mouse = lib.mapAttrs (_: val: "mouse:${toString val}") {
      left = 272;
      right = 273;
      middle = 274;
      sideRear = 275;
      sideFront = 276;
    };
    media = {
      mute = "XF86AudioMute";
      volumeUp = "XF86AudioRaiseVolume";
      volumeDown = "XF86AudioLowerVolume";
      play = "XF86AudioPlay";
      prev = "XF86AudioPrev";
      next = "XF86AudioNext";
    };
  };

  # Binaries

in
rec {
  inherit
    mods
    classes
    isPackage
    buttons
    selectors
    parameters
    validateMod
    titles
    ;

  # Helpers
  /**
    Generate a hyprland keybinding

    # Type
    ```
    mkBind :: { mods :: [ String ] | String, keys :: [ String ] | String, dispatcher :: String, params :: [ String ] } -> String
    ```
  */
  mkBind =
    {
      mods,
      keys,
      dispatcher,
      params ? [ ],
    }:
    [
      (mods |> toList |> concatStringsSep " ")
      (keys |> toList |> concatStringsSep "&")
      dispatcher
    ]
    ++ (toList params)
    |> concatStringsSep ", ";

  mkBind' =
    mods: keys: dispatcher: params:
    mkBind {
      inherit
        mods
        keys
        dispatcher
        params
        ;
    };

  exec =
    mods: keys: command:
    mkBind {
      inherit mods keys;
      dispatcher = "exec";
      params = [ command ];
    };

  execNamed =
    mods: keys: command: name:
    mkBind {
      inherit mods keys;
      dispatcher = "exec";
      params = [ command ];
    };

  execPkg =
    mods: keys: package:
    mkBind {
      inherit mods keys;
      dispatcher = "exec";
      params = [ (getExe package) ];
    };

  execSh =
    mods: keys: command:
    mkBind {
      inherit mods keys;
      dispatcher = "exec";
      params = [ command ];
    };

  execBg =
    mods: keys: command:
    mkBind {
      inherit mods keys;
      dispatcher = "exec";
      params = [ command ];
    };

  execSys =
    mods: keys: command:
    mkBind {
      inherit mods keys;
      dispatcher = "execr";
      params = [ command ];
    };

  execSysSh =
    mods: keys: command:
    mkBind {
      inherit mods keys;
      dispatcher = "exec";
      params = [ command ];
    };

  # Notifications
  mkNotification =
    {
      body,
      summary ? null,
      appName ? null,
      actions ? { },
      urgency ? null,
      expire ? null,
      icon ? null,
      transient ? false,
    }:
    let
      notify-send' = getExe' pkgs.libnotify "notify-send";
      option = name: val: optionalString (val != null) "-${name} ${val}";
    in
    [
      notify-send'
      (option "a" appName)
      (lib.mapAttrsToList (n: v: option "A" "${n}=${v}") actions)
      (option "t" expire)
      (option "i" icon)
      (optionalString (summary != null) summary)
      body
    ]
    |> lib.flatten
    |> builtins.filter (v: v != "")
    |> concatStringsSep " ";
}
