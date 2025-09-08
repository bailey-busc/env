{
  config,
  lib,
  self,
  inputs',
  pkgs,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption;
  inherit (lib.types)
    attrsOf
    submodule
    str
    package
    bool
    listOf
    ;
  inherit (self.lib) notIn;
  inherit (self.lib.modules)
    mkStrOpt'
    mkBoolOpt'
    mkIntOpt'
    mkNumberOpt'
    ;
  fontOption =
    description:
    mkOption {
      type = submodule {
        options = {
          package = mkOption {
            type = package;
            description = "Package for the font";
          };
          name = mkOption {
            type = str;
            description = "Name of the font";
          };
        };
      };
      inherit description;
    };
  fontOption' = kind: fontOption "Default font for ${kind}";

  cfg = config.env;
in
{
  options.env = {
    username = mkOption {
      type = str;
      default = "bailey";
      description = "Username for the environment";
    };
    home = mkOption {
      type = str;
      default = "/home/${cfg.username}";
      description = "Home directory for the environment";
    };
    deploy = {
      fresh = mkOption {
        type = bool;
        default =
          config.networking.hostName
          |> notIn [
            "orchid"
            "iris"
            "azalea"
          ];
        description = ''
          Whether this deployment is "fresh" or not, meaning the deployment has occurred at least once.
          This is important for determining whether or not the system can expect for certain paths to be present,
          for purposes such as populating initrd secrets.
        '';
      };
    };
    storage = {
      enable = mkEnableOption "disk partition management";
      device = mkStrOpt' "/dev/nvme0n1";
      swapSizeGb = mkIntOpt' 16;
      bootSizeGb = mkIntOpt' 16;
      tmpSizeGb = mkIntOpt' 64;
      rootTmpSizeGb = mkIntOpt' 128;
      zfs = {
        pools.root.name = mkStrOpt' "pool";
        datasets = {
          root.name = mkStrOpt' "nixos";
          user.name = mkStrOpt' "userdata";
        };
      };
    };
    displays = mkOption {
      type = attrsOf (
        submodule (
          { name, ... }:
          {
            options = {
              output = mkStrOpt' name;
              primary = mkBoolOpt' false;
              height = mkIntOpt' 1080;
              width = mkIntOpt' 1920;
              x = mkIntOpt' 0;
              y = mkIntOpt' 0;
              refresh = mkIntOpt' 60;
              scale = mkNumberOpt' 1;
            };
          }
        )
      );
      default = { };
      description = "Displays to configure";
    };
    hardware = {
      laptop.enable = mkEnableOption "Laptop configuration management";
      gpu = {
        nvidia.enable = mkEnableOption "Nvidia GPU configuration management";
        amd.enable = mkEnableOption "AMD GPU configuration management";
      };
    };
    theme = {
      fonts = {
        # Defaults
        serif = fontOption "Default serif font";
        sans = fontOption "Default sans serif font";
        mono = fontOption "Default monospace font";
        emoji = fontOption "Default emoji font";

        # Apps
        terminal = fontOption' "terminal";
        widgets = fontOption' "UI widgets like Rofi and fabric";
        statusBar = fontOption' "status bars like waybar";
        editor = {
          ui = fontOption' "text editor UI";
          buffer = fontOption' "text editor buffer";
          suggest = fontOption' "text editor suggest";
          docs = fontOption' "text editor docs";
        };
        extraFontPackages = mkOption {
          type = listOf package;
          default = [ ];
          description = "Extra font packages to install";
        };
      };
    };
  };
  config.env = {
    username = "bailey";
    theme.fonts =
      let
        appleFonts = inputs'.apple-fonts.packages;
      in
      rec {
        # System defaults
        sans = {
          name = "SF Pro";
          package = appleFonts.sf-pro-nerd;
        };
        serif = sans;
        mono = {
          name = "SF Mono";
          package = appleFonts.sf-mono-nerd;
        };
        emoji = {
          name = "Apple Color Emoji";
          package = inputs'.apple-emoji-linux.packages.default;
        };

        # Apps
        terminal = {
          # name = "Lilex";
          # name = "Monaspace Argon";
          name = "Maple Mono NF";
          # name = "Atkinson Hyperlegible Mono";
          # package = pkgs.lilex;
          # package = pkgs.monaspace;
          package = pkgs.maple-mono.NF;
          # package = pkgs.atkinson-hyperlegible-mono;
        };

        widgets = sans;
        statusBar = sans;

        editor = {
          ui = {
            name = "Inter Display";
            package = pkgs.inter;
          };
          buffer = {
            name = "Monaspace Argon Var";
            package = pkgs.monaspace;
          };
          suggest = {
            name = "Monaspace Krypton Var";
            package = pkgs.monaspace;
          };
          docs = {
            name = "Monaspace Xenon Var";
            package = pkgs.monaspace;
          };
        };
        extraFontPackages = with pkgs; [
          corefonts

          siji
          emacs-all-the-icons-fonts
          nerd-fonts.symbols-only

          monaspace

          atkinson-hyperlegible-mono
          atkinson-hyperlegible-next

          appleFonts.sf-mono
          appleFonts.sf-pro
          appleFonts.ny

          maple-mono.NF
        ];
      };
  };
}
