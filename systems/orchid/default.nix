{
  lib,
  config,
  pkgs,
  inputs,
  self,
  ...
}:
with lib;
with builtins;
let
  inherit (self.lib.modules) enabled;
  ctdataPath = "/mnt/ctdata";
in
{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-amd
    common-pc
    common-pc-ssd
    common-gpu-amd
    common-gpu-nvidia-nonprime
  ];

  networking = {
    hostId = "ac20e41a";
    interfaces = {
      ibp104s0f1.useDHCP = true;
      eno2.useDHCP = true;
      eno1.useDHCP = true;
    };
  };

  services = {
    zfs = {
      trim = enabled;
      autoScrub = {
        enable = true;
        pools = [
          "rpool"
          "bpool"
        ];
      };
    };
    xserver.videoDrivers = [ "nvidia" ];

    hardware.openrgb = enabled;
    # logind.settings.Login = {
    #   # don't shutdown when power button is short-pressed because i fucking destroyed the pwer button with a keyboard tray
    #   # HandlePowerKey = "ignore";
    # };
  };
  hardware = {
    firmware = lib.mkForce (
      with pkgs;
      [
        linux-firmware
        zd1211fw
        alsa-firmware
        sof-firmware
        libreelec-dvb-firmware
      ]
    );
    bluetooth = enabled;
    nvidia.modesetting.enable = true;
  };

  security.tpm2 = {
    enable = true;
    tctiEnvironment.enable = true;
  };

  systemIdentity = {
    enable = true;
    pcr15 = "a815d155639cb1ba7e8edca57235991929a99888c5dbac3061d01fccc0889253";
  };

  boot = {
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
    ];
    zfs = {
      extraPools = [
        "rpool"
        "bpool"
      ];
      devNodes = "/dev/disk/by-id";
    };
    loader = {
      systemd-boot.enable = lib.mkForce false;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
    initrd = {
      network.ssh = {
        enable = true;
        shell = "/bin/cryptsetup-askpass";
        authorizedKeys = map toString (
          config.users.users.bailey.openssh.authorizedKeys.keyFiles
          ++ config.users.users.glimpse.openssh.authorizedKeys.keyFiles
        );
        hostKeys = [
          "/etc/secrets/initrd/ssh_host_rsa_key"
          "/etc/secrets/initrd/ssh_host_ed25519_key"
        ];
      };
      luks.devices.luks-rpool = {
        device = "/dev/disk/by-uuid/208a9e57-0bd2-42c7-b4bc-06a3ed8d2c4f";
        crypttabExtraOpts = [
          "tpm2-device=auto"
          "tpm2-measure-pcr=yes"
        ];
        allowDiscards = true;
        bypassWorkqueues = true;
      };
      systemd = {
        enable = true;
        tpm2 = enabled;
      };
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "ahci"
        "usbhid"
        "sd_mod"
        "exfat"
        "amdgpu"
        "nvidia_drm"
        "nvidia_modeset"
        "nvidia"
        # Networking
        "igc"
        "atlantic"
        "mt7921e"
        # Unlock
        "tpm_crb"
        "tpm_tis"
      ];
    };

    kernelModules = [
      "ahci"
      "amdgpu"
      "atlantic"
      "coretemp"
      "exfat"
      "igc"
      "i2c-dev"
      "i2c-piix4"
      "k10temp"
      "kvm-amd"
      "mt7921e"
      "nvidia_drm"
      "nvidia_modeset"
      "nvidia"
      "nvme"
      "sd_mod"
      "thunderbolt"
      "usbhid"
      "v4l2loopback"
      "xhci_pci"
    ];
    supportedFilesystems = [
      "ntfs"
      "zfs"
    ];
    blacklistedKernelModules = [
      "nouveau"
      "bbswitch"
    ];
    #extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];
  };

  fileSystems =
    let
      pool = poolname: forBoot: name: {
        device = "${poolname}/${name}";
        fsType = "zfs";
        options = [
          "zfsutil"
          "X-mount.mkdir"
        ];
        neededForBoot = forBoot;
      };
      rpool = pool "rpool" false;
      bpool = pool "bpool" true;
    in
    {
      "/" = {
        fsType = "tmpfs";
        device = "tmpfs";
        options = [
          "defaults"
          "size=10G"
          "mode=755"
        ];
      };

      # OS Stuff
      "/nix" = rpool "nix";
      "/etc" = rpool "etc";
      "/var" = rpool "var";
      "/var/lib" = rpool "var/lib";
      "/var/log" = rpool "var/log";
      "/var/spool" = rpool "var/spool";

      # Home directories
      "/root" = rpool "users/root";
      "/home/bailey" = rpool "users/bailey";

      "/boot" = bpool "nixos";

      "/boot/efi" = {
        device = "/dev/disk/by-id/nvme-uuid.4561c70f-50d3-4276-a708-c2a132195a36-part5";
        fsType = "vfat";
        depends = [ "/boot" ];
        options = [
          "x-systemd.idle-timeout=1min"
          "x-systemd.automount"
          "noauto"
          "nofail"
          "noatime"
          "X-mount.mkdir"
        ];
      };

      # CT Data on Recon
      "${ctdataPath}" = {
        device = "//${self.lib.ips.recon}/ctdata";
        fsType = "cifs";
        options =
          let
            # this line prevents hanging on network split
            automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,nofail";
          in
          [
            "${automount_opts},credentials=${config.age.secrets.ctdata_credentials.path},vers=3.0,sec=ntlmssp"
          ];
      };

      "/tmp" = {
        fsType = "tmpfs";
        device = "tmpfs";
        options = [
          "nosuid"
          "nodev"
          "relatime"
          "size=100G"
          "mode=755"
        ];
      };
    };

  swapDevices = [
    {
      device = "/dev/disk/by-id/nvme-CT4000T700SSD3_2340E87BB309-part1";
      randomEncryption = {
        enable = true;
        allowDiscards = true;
      };
    }
  ];
  nix.settings.max-jobs = lib.mkDefault 16;

  # iPXE
  # Enable and configure DHCP server
  # services.dnsmasq =
  #   let
  #     network = {
  #       interface = "eth0";
  #       subnet = "192.168.1.0";
  #       netmask = "255.255.255.0";
  #       range = "192.168.1.100 192.168.1.200";
  #       gateway = "192.168.1.1";
  #       dns = "192.168.1.1";
  #       tftpServer = "192.168.1.50"; # IP address of your TFTP server
  #       filename = "netboot.xyz.kpxe";
  #     };
  #   in
  #   {
  #     enable = true;
  #     settings = {
  #       interface = network.interface;
  #       dhcpRange = "${network.range},12h";
  #       dhcpOption = [
  #         "3,${network.gateway}" # Gateway
  #         "6,${network.dns}" # DNS server
  #         "66,${network.tftpServer}" # TFTP server
  #         "67,${network.filename}" # Boot file
  #       ];
  #       enableTFTP = true;
  #       tftpRoot = "/var/lib/tftpboot";
  #     };
  #   };

  # # Enable and configure TFTP server
  # services.atftpd = {
  #   enable = true;
  #   root = "/var/lib/tftpboot";
  #   extraOptions = [
  #     "--bind-address 0.0.0.0"
  #   ];
  # };

  # # Environment settings for TFTP boot files
  # environment.etc = {
  #   "netboot.xyz.kpxe".source = pkgs.fetchurl {
  #     url = "https://boot.netboot.xyz/ipxe/netboot.xyz.kpxe";
  #     sha256 = "sha256-ucMs36nRY+zSNi/XH6dAod5RZN65D4FGfnCoRT9AfqU=";
  #   };
  #   "tftpboot".text = ''
  #     mkdir -p /var/lib/tftpboot
  #     chown atftpd:atftpd /var/lib/tftpboot
  #     chmod 755 /var/lib/tftpboot
  #   '';
  # };

  env = {
    hardware.gpu = {
      amd.enable = true;
      nvidia.enable = true;
    };
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
    };
    profiles = {
      graphical = enabled;
      # server = {
      #   vscode-server = enabled;
      # };
    };
    displays =
      let
        display = offset: output: {
          width = 2560;
          height = 1440;
          x = offset;
          y = 0;
          inherit output;
          refresh = 120;
          scale = 1;
        };
      in
      rec {
        left = display 0 "DP-3";
        right = display left.width "DP-4";
      };
  };
}
