{ inputs, ... }:
let
  inherit (builtins) getAttr;
  inherit (inputs.lib.lib)
    attrByPath
    getAttrFromPath
    flip
    concatMap
    unique
    ;
in
rec {
  getInputs = map (flip getAttr inputs);
  # string -> string -> [string] -> [modules]
  mkCollect =
    attr: fallbackAttr: inputsToCollect:
    map (
      inputName:
      let
        input = inputs.${inputName};
        attrNamed = attrByPath (attr ++ [ inputName ]) attrDefault input;
        attrDefault = attrByPath (attr ++ [ "default" ]) fallback input;
        fallback = attrByPath fallbackAttr fallbackNamed input;
        fallbackNamed = attrByPath (fallbackAttr ++ [ inputName ]) fallbackDefault input;
        fallbackDefault = getAttrFromPath (fallbackAttr ++ [ "default" ]) input;
      in
      attrNamed
    ) inputsToCollect;
  mkCollectAll =
    attr: fallbackAttr: inputsToCollect:
    concatMap (
      inputName:
      let
        input = inputs.${inputName};
        default = attrByPath attr fallback input;
        fallback = getAttrFromPath fallbackAttr input;
      in
      unique default
    ) inputsToCollect;
  collectHmModules = mkCollect [ "homeModules" ] [ "homeManagerModules" ];
  collectHmModulesAll = mkCollectAll [ "homeModules" ] [ "homeManagerModules" ];
  collectNixOSModules = mkCollect [ "nixosModules" ] [ "nixosModule" ];
  collectNixOSModulesAll = mkCollectAll [ "nixosModules" ] [ "nixosModule" ];
  collectDarwinModules = mkCollect [ "darwinModules" ] [ "darwinModule" ];
  collectDarwinModulesAll = mkCollectAll [ "darwinModules" ] [ "darwinModule" ];
  collectOverlays = mkCollect [ "overlays" ] [ "overlay" ];
  collectOverlaysAll = mkCollectAll [ "overlays" ] [ "overlay" ];
}
