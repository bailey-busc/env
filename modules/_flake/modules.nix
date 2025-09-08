# Collect all of the nixos modules defined in modules/nixos and modules/home
# Automatically discovers modules recursively and names them following established patterns
{
  lib,
  self,
  ...
}:
let
  inherit (lib)
    removePrefix
    removeSuffix
    ;
  discoverModules =
    moduleKind:
    let
      moduleDir = toString "${self}/modules/${moduleKind}";
    in
    self.lib.fs.getDefaultNixFilesRecursive moduleDir
    |> map (modulePath: {
      name =
        builtins.unsafeDiscardStringContext modulePath
        |> removePrefix "${moduleDir}/"
        |> removeSuffix "/default.nix";
      value = modulePath;
    })
    |> builtins.listToAttrs;
in
{
  flake = {
    homeModules = discoverModules "home";
    nixosModules = discoverModules "nixos";
    darwinModules = discoverModules "darwin";
    flakeModules = discoverModules "flake";
  };
}
