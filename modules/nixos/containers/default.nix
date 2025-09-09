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
    podman = {
      enable = true;
      dockerCompat = !dockerEnabled;
      dockerSocket.enable = !dockerEnabled;
      autoPrune.enable = true;
      extraPackages = with pkgs; [
        gvisor
        zfs
      ];
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
        podman-compose
        podman-tui
      ])
    ]
  );
}
