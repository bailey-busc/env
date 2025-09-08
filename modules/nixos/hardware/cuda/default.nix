{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cpkgs = pkgs.cudaPackages_12;
  cudaDeps = [
    (pkgs.runCommandLocal "crt" { } ''
      mkdir -p $out/include/crt

      cp -r ${cpkgs.cuda_cudart.dev}/include/* $out/include/crt/
    '')

    cpkgs.cuda_cccl
    cpkgs.cuda_cudart
    cpkgs.cuda_nvcc
    cpkgs.cuda_nvprof
    #cpkgs.tensorrt
    cpkgs.cudatoolkit
    cpkgs.cudnn
    cpkgs.cutensor
    cpkgs.libcublas
    cpkgs.libcufft
    cpkgs.libcufile
    cpkgs.libcurand
    cpkgs.libcusolver
    cpkgs.libcusparse
    cpkgs.nccl
    cpkgs.nvidia_fs

    pkgs.freeglut
    pkgs.xorg.libX11
    pkgs.xorg.libXext
    pkgs.xorg.libXi
    pkgs.xorg.libXmu
    pkgs.xorg.libXrandr
    pkgs.xorg.libXv
    pkgs.zlib
    config.hardware.nvidia.package
  ];
in
{
  config = mkIf config.env.hardware.gpu.nvidia.enable {
    hardware.nvidia.open = mkDefault false;
    environment = {
      systemPackages = with pkgs; [ nvtopPackages.full ] ++ cudaDeps;
      sessionVariables = {
        NVIDIA_DRIVER_CAPABILITIES = "compute,utility";
        CUDA_PATH = pkgs.cudatoolkit;
        CUDATKDIR = pkgs.cudatoolkit;
        EXTRA_LDFLAGS = "-L${config.hardware.nvidia.package}/lib -L/run/opengl-driver/lib";
      };
    };
    programs.nix-ld.libraries = cudaDeps;
  };
}
