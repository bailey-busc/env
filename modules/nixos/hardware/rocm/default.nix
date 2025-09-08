{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkIf config.env.hardware.gpu.amd.enable {
    hardware.amdgpu.opencl.enable = true;
    environment = {
      systemPackages = with pkgs.rocmPackages; [
        hipblas
        hipsparse
        rocsparse
        rocrand
        rocthrust
        rocsolver
        rocfft
        hipcub
        rocprim
        rccl
        clr
        clr.icd
        hipcc
      ];
      sessionVariables.ROCM_HOME = pkgs.rocmPackages.clr;
    };
  };
}
