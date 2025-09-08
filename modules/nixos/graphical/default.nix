{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  inherit (config.env) profiles;
in
mkIf profiles.graphical.enable {
  security.pam.services = mkMerge [
    {
      login.enableGnomeKeyring = true;
    }
    (mkIf config.home-manager.users.${config.env.username}.programs.hyprlock.enable {
      hyprlock = { };
    })
  ];
  hardware.graphics = with pkgs; {
    extraPackages = [
      amdvlk
      vaapiVdpau
    ];
    extraPackages32 = [
      driversi686Linux.amdvlk
      driversi686Linux.mesa
    ];
  };
  boot = {
    plymouth = {
      enable = true;
      theme = lib.mkForce "breeze";
    };
    extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  };
  environment = {
    pathsToLink = [
      "/share/xdg-desktop-portal"
      "/share/applications"
    ];
    variables.XDG_RUNTIME_DIR = "/run/user/$UID";
  };
  xdg.portal = {
    enable = true;
    config.common.default = "*";
  };
  services = {
    printing = {
      enable = true;
      drivers = with pkgs; [
        hplip
        hplipWithPlugin
        gutenprint
        gutenprintBin
        epson-escpr
      ];
    };
    flatpak.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    gnome.gnome-keyring.enable = true;
    keyd = {
      enable = true;
      keyboards.default.settings.main = {
        capslock = "overload(mod3, mod3)";
      };
    };
    teamviewer.enable = true;
    dbus.implementation = "broker";
  };

  programs = {
    gnome-disks.enable = true;
    dconf.enable = true;
    nix-ld.libraries = with pkgs; [
      xorg.libX11
      xorg.libXcursor
      xorg.libxcb
      xorg.libXi
      libGL
      vulkan-loader
      glfw
      libxkbcommon
      libxkbcommon.dev
      wayland
      alsa-lib
      libpulseaudio
      libjack2
    ];
  };
  systemd = {
    slices = {
      # High-level user slice with generous limits
      "user" = {
        sliceConfig = {
          TasksMax = "65536"; # Very high thread limit
          MemoryMax = "infinity"; # No memory restrictions
          CPUQuota = "800%"; # Allow 8 CPU cores
          IOWeight = "200"; # Higher I/O priority
        };
      };

      # Compositor slice - isolated resources for Hyprland
      "compositor" = {
        description = "Wayland Compositor Slice";
        sliceConfig = {
          TasksMax = "8192"; # Adequate for compositor + helpers
          MemoryHigh = "4G"; # Soft memory limit
          MemoryMax = "6G"; # Hard memory limit
          CPUQuota = "400%"; # 4 CPU cores max
          IOWeight = "300"; # High I/O priority for compositor

          # GPU and real-time scheduling for smooth compositing
          DeviceAllow = [
            "/dev/dri rw" # GPU access
            "/dev/input rw" # Input devices
          ];
        };
      };
      # Application slice - main user applications
      "applications" = {
        description = "User Applications";
        sliceConfig = {
          TasksMax = "32768"; # High limit prevents threading issues
          MemoryHigh = "12G"; # Soft limit for app memory
          MemoryMax = "16G"; # Hard limit
          CPUQuota = "600%"; # 6 CPU cores
          IOWeight = "150"; # Standard I/O priority

          # Prevent OOM killer from interfering
          ManagedOOMMemoryPressure = "none";
          ManagedOOMSwap = "none";
        };
      };

      # Background services slice - lower priority
      "background" = {
        description = "Background Services and Utilities";
        sliceConfig = {
          TasksMax = "4096"; # Lower limit for background tasks
          MemoryHigh = "2G";
          MemoryMax = "4G";
          CPUQuota = "200%"; # 2 CPU cores
          IOWeight = "50"; # Low I/O priority
          Nice = "10"; # Lower process priority
        };
      };
      # Gaming slice - high-performance applications
      "gaming" = {
        description = "Gaming and High-Performance Applications";
        sliceConfig = {
          TasksMax = "16384"; # High thread count for games
          MemoryMax = "infinity"; # No memory limits for gaming
          CPUQuota = "800%"; # All available CPU cores
          IOWeight = "400"; # Maximum I/O priority
          Nice = "-5"; # Higher process priority

          # GPU and device access for gaming
          DeviceAllow = [
            "/dev/dri rw"
            "/dev/input rw"
            "/dev/js0 rw" # Joystick access
          ];
        };
      };
    };
    user.slices = {
      # Override default graphical session slice
      "session" = {
        sliceConfig = {
          TasksMax = "16384"; # High limit for session components
          MemoryHigh = "8G";
          MemoryMax = "12G";
          CPUQuota = "500%";
        };
      };

      # Apps launched by compositor
      "app-graphical" = {
        sliceConfig = {
          TasksMax = "24576"; # Very high for GUI apps
          MemoryHigh = "10G";
          MemoryMax = "14G";
          CPUQuota = "600%";
          IOWeight = "200";
        };
      };

      # Background user services
      "background-graphical" = {
        sliceConfig = {
          TasksMax = "2048";
          MemoryHigh = "1G";
          MemoryMax = "2G";
          CPUQuota = "100%";
          IOWeight = "50";
          Nice = "10";
        };
      };
    };
  };
}
