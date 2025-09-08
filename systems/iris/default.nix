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
  displayCfg = config.env.displays;
in
{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-amd
    common-pc
    common-pc-ssd
    common-gpu-amd
    common-gpu-nvidia-nonprime

    ./filesystems.nix
  ];

  networking = {
    hostName = "iris";
    hostId = "ac20e41a";
  };

  services = {
    zfs = {
      trim = enabled;
      autoScrub = {
        enable = true;
        pools = [
          "npool"
          "spool"
        ];
      };
    };
    xserver.videoDrivers = [
      "nvidia"
      "amd"
    ];
    hardware.openrgb = {
      enable = true;
      motherboard = "amd";
    };

    blueman = enabled;

  };

  # systemd.tmpfiles.rules = [
  #   "L+ /run/amd-igpu - - - - /dev/dri/by-path/pci-0000:0d:00.0-card"
  #   # "L+ /run/nvidia-gpu - - - - /dev/dri/by-path/pci-0000:01:00.0-card"
  #   "L+ /run/nvidia-gpu - - - - /dev/dri/by-path/pci-0000:01:00.0-platform-simple-framebuffer.0-card"
  # ];

  # environment.sessionVariables.AQ_DRM_DEVICES = "/run/nvidia-gpu:/run/amd-igpu";

  hardware = {
    bluetooth = {
      enable = true;
      settings = {
        General = {
          ControllerMode = "bredr";
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
    nvidia = {
      modesetting = enabled;
      open = true;
    };
  };

  boot = {
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "pcie_port_pm=off"
      "pcie_aspm.policy=performance"
      "iwlwifi.wd_disable=1"
    ];
    kernelPackages = pkgs.linuxKernel.packages.linux_6_12;
    zfs = {
      allowHibernation = true;
      forceImportRoot = false;
      extraPools = [
        "npool"
        "spool"
      ];
      devNodes = "/dev/disk/by-id";
    };
    loader = {
      systemd-boot.enable = lib.mkForce true;
      efi = {
        efiSysMountPoint = "/boot";
        canTouchEfiVariables = true;
      };
    };
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "sd_mod"
        "exfat"
        "amdgpu"
      ];
      systemd = {
        enable = true;
        tpm2.enable = true;
      };
    };
    kernelModules = [
      "kvm-amd"
      "coretemp"
      "k10temp"
      "amdgpu"
      "v4l2loopback"
      "i2c-dev"
      "i2c-piix4"
    ];
    supportedFilesystems = [
      "ntfs"
      "zfs"
    ];
    blacklistedKernelModules = [
      "nouveau"
      "bbswitch"
    ];
  };

  nix.settings.max-jobs = lib.mkDefault 16;
  programs = {
    gamescope = {
      enable = true;
      args = [
        "--rt"
        "--expose-wayland"
      ];
    };
    steam = {
      enable = true;
      protontricks.enable = true;
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
      extraPackages = with pkgs; [
        openssl
        nghttp2
        libidn2
        rtmpdump
        libpsl
        curl
        krb5
        keyutils
        mangohud
      ];
    };
  };

  env = {
    #profiles.server.open-webui.enable = true;
    hardware.gpu = {
      amd.enable = true;
      nvidia.enable = true;
    };
    # Consolidated WireGuard configuration
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

      tui.enable = false; # Enable if TUI monitoring is desired

      # Manual peers (non-flake systems)
      peers = {
        "iphone" = {
          publicKey = builtins.readFile "${inputs.self}/data/secrets/wireguard/iphone.pub";
          ip = "10.100.0.99";
          allowedIPs = [ "10.100.0.99/32" ];
          # No endpoint for mobile devices (they connect to us)
        };
      };
    };
    displays = {
      left = {
        width = 1920;
        height = 1080;
        x = 0;
        y = 0;
        output = "DP-1";
        refresh = 60;
      };
      primary_left = {
        width = 2560;
        height = 1440;
        x = builtins.floor <| displayCfg.left.width / displayCfg.left.scale;
        y = 0;
        output = "DP-2";
        refresh = 180;
        scale = 1.25;
      };
      primary_right = {
        width = 2560;
        height = 1440;
        x =
          displayCfg.primary_left.x
          + (builtins.floor <| displayCfg.primary_left.width / displayCfg.primary_left.scale);
        y = 0;
        output = "DP-4";
        refresh = 180;
        scale = 1.25;

      };
      right = {
        width = 1920;
        height = 1080;
        x =
          displayCfg.primary_right.x
          + (builtins.floor <| displayCfg.primary_right.width / displayCfg.primary_right.scale);
        y = 0;
        output = "DP-3";
        refresh = 60;
      };
      tv = {
        width = 3840;
        height = 2160;
        x = displayCfg.right.x + (builtins.floor <| displayCfg.right.width / displayCfg.right.scale);
        y = 0;
        output = "desc:Panasonic Industry Company Panasonic-TV 0x01015456";
        refresh = 120;
        scale = 1.5;
      };
    };
  };
}
