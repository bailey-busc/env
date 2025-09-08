# Flake module that implements a WireGuard mesh network
{
  config,
  lib,
  flake-parts-lib,
  ...
}:
{
  options =
    let
      inherit (lib) types;
    in
    {

      flake = flake-parts-lib.mkSubmoduleOptions {
        wireguard = lib.mkOption {
          type = types.submoduleWith { modules = [ ]; };
          description = '''';
        };
      };

    };
  config = {
    perSystem =
      { pkgs, self', ... }:
      {
      };
  };
}
