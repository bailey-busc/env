{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  podmanEnabled = config.virtualisation.podman.enable;
  dockerEnabled = config.virtualisation.docker.enable;
in
{
  virtualisation = {
    containers = {
      enable = true;
      policy = {
        default = [ { type = "insecureAcceptAnything"; } ];
        transports = {
          docker-daemon = {
            "" = [ { type = "insecureAcceptAnything"; } ];
          };
        };
      };
    };
    libvirtd = {
      enable = true;
      qemu = {
        runAsRoot = true;
        package = pkgs.qemu_kvm;
      };
    };
    podman = {
      enable = true;
      dockerCompat = !dockerEnabled;
      dockerSocket.enable = !dockerEnabled;
      autoPrune.enable = true;
      extraPackages = with pkgs; [ gvisor ];
    };
    docker = {
      enable = true;
      storageDriver =
        if
          (config.fileSystems ? "/var/lib/docker" && config.fileSystems."/var/lib/docker".fsType == "zfs")
        then
          "zfs"
        else
          "overlay2";
    };
  };
  hardware.nvidia-container-toolkit.enable = config.hardware.nvidia.enabled;

  environment.systemPackages = mkMerge (
    with pkgs;
    [
      [
        grype
        skopeo
        spice
        spice-gtk
        spice-protocol
        syft
        trivy
        virglrenderer
        virt-manager
        virt-viewer
        virtiofsd
        win-virtio
      ]
      (mkIf dockerEnabled [
        docker
        docker-compose
        dockfmt
      ])
      (mkIf podmanEnabled [
        podman
        podman-desktop
        podman-tui
      ])
    ]
  );
}
