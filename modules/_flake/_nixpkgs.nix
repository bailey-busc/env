# Configure nixpkgs in one place
{
  system,
  nixpkgs,
  overlays ? [ ],
  extraConfig ? { },
  ...
}:
import nixpkgs {
  inherit system overlays;
  config = {
    nvidia.acceptLicense = true;
    permittedInsecurePackages = [
      "electron-33.4.11"
      "python-2.7.18.8-env"
      "python-2.7.18.8"
    ];
    allowUnfree = true;
    #cudaSupport = true;
    #cudaVersion = "12.4";
  }
  // extraConfig;
}
