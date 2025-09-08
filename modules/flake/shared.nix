{
  self,
  lib,
  flake-parts-lib,
  moduleLocation,
  ...
}:
let
  inherit (lib)
    mapAttrs
    mkOption
    types
    ;
  inherit (flake-parts-lib)
    mkSubmoduleOptions
    ;
in
{
  options = {
    flake = mkSubmoduleOptions {
      sharedModules = mkOption {
        type = types.lazyAttrsOf types.deferredModule;
        default = { };
        apply = mapAttrs (
          k: v: {
            _file = "${toString moduleLocation}#sharedModules.${k}";
            imports = [ v ];
          }
        );
        description = ''
          Shared modules between Darwin and NixOS.

          You may use this for reusable pieces of configuration, service modules, etc.
        '';
      };
    };
  };
}
