{
  lib,
  config,
  pkgs,
  inputs,
  self,
  ...
}:
let
  inherit (self.lib.modules) enabled;
in
{
  imports = with inputs.nixos-hardware.nixosModules; [
    lenovo-thinkpad-p16s-amd-gen2
    ./filesystems.nix
  ];

  networking.hostId = "4b7cd901";

  programs.light.enable = true;

  services = {
    zfs = {
      trim.enable = true;
      autoScrub = {
        enable = true;
        pools = [ "pool" ];
      };
    };
    xserver.videoDrivers = [
      "modesetting"
      # "displaylink"
    ];
    fwupd.enable = true;

    actkbd = {
      enable = true;
      bindings =
        let
          increment = 5;
        in
        [
          # Brightness
          {
            keys = [ 224 ];
            events = [ "key" ];
            command = "${lib.getExe pkgs.light} -U ${toString increment}";
          }
          {
            keys = [ 225 ];
            events = [ "key" ];
            command = "${lib.getExe pkgs.light} -A ${toString increment}";
          }
        ];
    };
  };

  boot = {
    kernelParams = [ "video=eDP-1:3840x2160@80" ];
    zfs = {
      extraPools = [ "pool" ];
      devNodes = "/dev/disk/by-id";
    };
    loader.systemd-boot = {
      enable = true;
      consoleMode = "auto";
    };
    initrd = {
      availableKernelModules = [
        "nvme"
        "ehci_pci"
        "xhci_pci"
        "usb_storage"
        "sd_mod"
        "rtsx_pci_sdmmc"
      ];
      systemd = {
        enable = true;
        tpm2.enable = true;
      };
    };
    kernelModules = [ "kvm-amd" ];
  };

  nix.settings.max-jobs = lib.mkDefault 8;

  # environment.sessionVariables.AQ_DRM_DEVICES = "/dev/dri/card1";

  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        amdvlk
        rocmPackages.clr.icd
        rocmPackages.clr
        # Important for AMD GPUs with Hyprland
        mesa
      ];
    };
    bluetooth = {
      enable = true;
      settings = {
        General = {
          ControllerMode = "bredr";
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
  };
  env = {
    hardware = {
      laptop.enable = true;
      gpu.amd.enable = true;
    };
    storage = enabled;
    network.wireguard = {
      enable = true;

      # Basic WireGuard settings
      interfaceName = "wg0";
      privateKeyFile = config.age.secrets.wireguard_private.path;
      listenPort = 51820;

      # This node's services
      self.services = {
        "ssh" = {
          port = 22;
          protocol = "tcp";
          description = "SSH access";
        };
        "open-webui" = {
          port = 8080;
          protocol = "tcp";
          description = "Open WebUI service";
        };
      };

      # Magic DNS configuration
      magicDNS = {
        enable = true;
        domain = "mesh.local";
        upstreamDNS = [
          "1.1.1.1"
          "8.8.8.8"
        ];
      };

      # Enhanced features
      monitoring = {
        enable = true;
        prometheus = {
          enable = true;
          port = 9586;
          scrapeInterval = 15;
        };
        grafana.enable = false; # Enable later if needed
      };

      security = {
        enable = true;
        intrusion = {
          enableDetection = true;
          enablePrevention = false; # Conservative for server
          alertThreshold = 10;
        };
        trafficObfuscation.enable = false; # Enable if needed
      };

      keyRotation = {
        enable = true;
        interval = "monthly";
        backupCount = 3;
      };

      health = {
        enable = true;
        checkInterval = 30;
        connectivity = {
          timeout = 5;
          failureThreshold = 3;
        };
        recovery = {
          enable = true;
          actions = [
            "restart-interface"
            "notify-admin"
          ];
        };
      };
    };
    displays.eDP-1 = {
      width = 2560;
      height = 1440;
      scale = 2;
    };
  };
}
