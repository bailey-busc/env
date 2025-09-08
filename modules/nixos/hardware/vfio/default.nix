{
  lib,

  config,
  ...
}:
let
  inherit (lib)
    mkIf
    concatStringsSep
    types
    mkEnableOption
    ;
  cfg = config.env.hardware.pcie_passthrough;
in
{
  options.env.hardware.pcie_passthrough = with types; {
    enable = mkEnableOption "Enable PCIe passthrough";
    gpuIDs = mkOption {
      type = listOf string;
      default = [ ];
      description = "The PCIe device IDs to pass through";
    };
  };

  config = mkIf cfg.enable {
    boot = {
      initrd = {
        availableKernelModules = [
          "amdgpu"
          "vfio-pci"
        ];
        preDeviceCommands = ''
          ${concatStringsSep "\n" (
            map (id: "echo 'vfio-pci' > /sys/bus/pci/devices/${id}/driver_override") cfg.gpuIDs
          )}
            modprobe -i vfio-pci
        '';
        kernelModules = [
          "vfio_pci"
          "vfio"
          "vfio_iommu_type1"
          "vfio_virqfd"
        ];
      };

      kernelParams = [
        # enable IOMMU
        "amd_iommu=on"
        "pcie_aspm=off"
        ("vfio-pci.ids=" + concatStringsSep "," cfg.gpuIDs)
      ];
      kernelModules = [ "kvm-amd" ];
    };

    hardware.graphics.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;
  };
}
