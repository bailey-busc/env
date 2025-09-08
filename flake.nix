{
  description = "Bailey's NixOS configuration";
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    extra-experimental-features = [ "pipe-operators" ];
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      imports = with inputs; [
        home-manager.flakeModules.default
        treefmt-nix.flakeModule
        agenix-rekey.flakeModule
        pre-commit-hooks.flakeModule
        # actions-nix.flakeModules.default

        ./modules/flake/darwin.nix
        ./modules/flake/shared.nix

        ./modules/_flake/checks.nix
        ./modules/_flake/darwin.nix
        ./modules/_flake/deploy.nix
        ./modules/_flake/home.nix
        ./modules/_flake/lib.nix
        ./modules/_flake/modules.nix
        ./modules/_flake/nixos.nix
        ./modules/_flake/overlays.nix
        ./modules/_flake/packages.nix
        ./modules/_flake/nixpkgs.nix
        ./modules/_flake/shells.nix
      ];

      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          treefmt = {
            programs = {
              nixfmt = {
                enable = pkgs.lib.meta.availableOn pkgs.stdenv.buildPlatform pkgs.nixfmt-rfc-style.compiler;
                package = pkgs.nixfmt-rfc-style;
              };
              ruff = {
                check = true;
                format = true;
              };
              shellcheck.enable = true;
            };
            settings.formatter = {
              ruff-check.priority = 1;
              ruff-format.priority = 2;
            };
          };
        };
    };

  inputs = {
    nixpkgs.follows = "nixpkgs-25_05";
    nixpkgs-weekly.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/*";
    nixpkgs-unstable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*";
    nixpkgs-25_05.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2505.*";
    nixpkgs-24_11.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2411.*";
    nixpkgs-24_05.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2405.*";

    # Cheap lib instance
    lib.url = "github:nix-community/nixpkgs.lib";

    # Hardware
    nixos-hardware.url = "https://flakehub.com/f/NixOS/nixos-hardware/*";
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
    disko = {
      url = "https://flakehub.com/f/nix-community/disko/1.*";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    lanzaboote = {
      url = "https://flakehub.com/f/nix-community/lanzaboote/0.4.*";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
        flake-parts.follows = "flake-parts";
        flake-compat.follows = "flake-compat";
        crane.follows = "crane";
      };
    };

    # Home
    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0.1.*";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Apple
    nix-darwin = {
      # url = "https://flakehub.com/f/nix-darwin/nix-darwin/0.2505.*";
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0.1.*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    apple-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    apple-emoji-linux = {
      url = "github:samuelngs/apple-emoji-linux?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Themes / Visual
    base16.url = "github:SenchoPens/base16.nix";
    icon-browser = {
      url = "github:aylur/icon-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    branding = {
      url = "github:nixos/branding";
      inputs = {
        nixpkgs.follows = "nixpkgs-25_05";
        treefmt-nix.follows = "treefmt-nix";
        pre-commit-hooks.follows = "pre-commit-hooks";
      };
    };

    # Security
    agenix = {
      url = "https://flakehub.com/f/ryantm/agenix/*";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        darwin.follows = "nix-darwin";
      };
    };
    agenix-rekey = {
      url = "https://flakehub.com/f/oddlama/agenix-rekey/*";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
        flake-parts.follows = "flake-parts";
      };
    };
    nix-rage = {
      url = "github:renesat/nix-rage/v0.2.0";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
        pre-commit-hooks.follows = "pre-commit-hooks";
        crane.follows = "crane";
        systems.follows = "systems";
        flake-parts.follows = "flake-parts";
      };
    };

    # Hyprland
    hyprland = {
      # url = "https://flakehub.com/f/hyprwm/Hyprland/0.50.*";
      url = "github:hyprwm/hyprland/v0.50.0";
      inputs.nixpkgs.follows = "nixpkgs-weekly";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins/v0.50.0";
      inputs.hyprland.follows = "hyprland";
    };
    hypridle = {
      url = "github:hyprwm/hypridle/v0.1.6";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
        hyprlang.follows = "hyprland/hyprlang";
        hyprutils.follows = "hyprland/hyprutils";
        hyprland-protocols.follows = "hyprland/hyprland-protocols";
        hyprwayland-scanner.follows = "hyprland/hyprwayland-scanner";
      };
    };
    hyprhook = {
      url = "github:Hyprhook/Hyprhook";
      inputs.hyprland.follows = "hyprland";
    };
    hyprland-virtual-desktops = {
      url = "github:bailey-busc/hyprland-virtual-desktops?rev=5351b1a2eee80c868ace3778f15d06c255002da2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quickshell = {
      # add ?ref=<tag> to track a tag
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";

      # THIS IS IMPORTANT
      # Mismatched system dependencies will lead to crashes and other issues.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ignis = {
      url = "github:ignis-sh/ignis";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        ignis-gvc.follows = "ignis-gvc";
      };
    };
    ignis-gvc = {
      url = "github:ignis-sh/ignis-gvc";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Emacs
    nix-doom-emacs-unstraightened = {
      url = "github:marienz/nix-doom-emacs-unstraightened/3f42ce0004a2de2a25c832f7ed71507d82e2c6ce";
      inputs = {
        nixpkgs.follows = "";
        doomemacs.follows = "doomemacs";
        emacs-overlay.follows = "emacs-overlay";
        systems.follows = "systems";
      };
    };
    doomemacs = {
      url = "github:doomemacs/doomemacs/751ac6134b6abe204d9c514d300343b07b26da3c?"; # Frozen
      flake = false;
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay/382428e9af7df6b10ad9caefcad0ca8322d5e352";
      inputs = {
        nixpkgs-stable.follows = "";
        nixpkgs.follows = "";
      };
    };
    doomconf = {
      url = "github:bailey-busc/.doom.d";
      flake = false;
    };

    # Rust
    crane.url = "https://flakehub.com/f/ipetkov/crane/*";
    rust-overlay = {
      url = "https://flakehub.com/f/oxalica/rust-overlay/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Ad blocking
    adblock-unbound = {
      url = "github:MayNiklas/nixos-adblock-unbound";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        adblockStevenBlack.follows = "adblock-hosts";
      };
    };
    adblock-hosts = {
      url = "github:StevenBlack/hosts";
      flake = false;
    };

    # Additional package sets
    jujutsu.url = "github:gusinacio/jj/lfs";
    mozilla.url = "github:mozilla/nixpkgs-mozilla";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/*";
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    audio = {
      url = "github:polygon/audio.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };
    nixpkgs-terraform = {
      url = "github:stackbuilders/nixpkgs-terraform";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    zed-editor = {
      url = "github:Rishabh5321/zed-editor-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs-weekly";
        flake-parts.follows = "flake-parts";
      };
    };
    easy-purescript-nix = {
      url = "github:justinwoo/easy-purescript-nix";
      inputs.flake-utils.follows = "flake-utils";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    nil = {
      url = "github:oxalica/nil";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zjstatus = {
      url = "github:dj95/zjstatus";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
        flake-utils.follows = "flake-utils";
        crane.follows = "crane";
      };
    };
    erosanix = {
      url = "github:emmanuelrosa/erosanix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };

    # Flakes infrastructure/boilerplate/garbage
    systems.url = "github:nix-systems/default";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/*";
    flake-utils = {
      url = "https://flakehub.com/f/numtide/flake-utils/*";
      inputs.systems.follows = "systems";
    };
    flake-parts = {
      url = "https://flakehub.com/f/hercules-ci/flake-parts/*";
      inputs.nixpkgs-lib.follows = "lib";
    };
    actions-nix.url = "github:nialov/actions.nix";
    pre-commit-hooks = {
      url = "https://flakehub.com/f/cachix/git-hooks.nix/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Deployment
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
        utils.follows = "flake-utils";
      };
    };

    lfs = {
      url = "path:/home/bailey/lfs";
      flake = false;
    };
  };
}
