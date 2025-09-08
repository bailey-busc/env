{ inputs, ... }:
let
  inherit (inputs.lib.lib)
    mapAttrsToList
    recursiveUpdate
    mergeAttrs
    flatten
    ;
  inherit (builtins) foldl mapAttrs isDerivation;
in
{
  ## Map and flatten an attribute set into a list.
  ## Example Usage:
  ## ```nix
  ## mapConcatAttrsToList (name: value: [name value]) { x = 1; y = 2; }
  ## ```
  ## Result:
  ## ```nix
  ## [ "x" 1 "y" 2 ]
  ## ```
  #@ (a -> b -> [c]) -> Attrs -> [c]
  mapConcatAttrsToList = f: attrs: flatten (mapAttrsToList f attrs);

  ## Recursively merge a list of attribute sets.
  ## Example Usage:
  ## ```nix
  ## mergeDeep [{ x = 1; } { x = 2; }]
  ## ```
  ## Result:
  ## ```nix
  ## { x = 2; }
  ## ```
  #@ [Attrs] -> Attrs
  mergeDeep = foldl recursiveUpdate { };

  ## Merge the root of a list of attribute sets.
  ## Example Usage:
  ## ```nix
  ## mergeShallow [{ x = 1; } { x = 2; }]
  ## ```
  ## Result:
  ## ```nix
  ## { x = 2; }
  ## ```
  #@ [Attrs] -> Attrs
  mergeShallow = foldl mergeAttrs { };

  ## Merge shallow for packages, but allow one deeper layer of attribute sets.
  ## Example Usage:
  ## ```nix
  ## merge-shallow-packages [ { inherit (pkgs) vim; some.value = true; } { some.value = false; } ]
  ## ```
  ## Result:
  ## ```nix
  ## { vim = ...; some.value = false; }
  ## ```
  #@ [Attrs] -> Attrs
  mergeShallowPackages =
    items:
    foldl (
      result: item:
      result
      // (mapAttrs (
        name: value:
        if isDerivation value then
          value
        else if builtins.isAttrs value then
          (result.${name} or { }) // value
        else
          value
      ) item)
    ) { } items;
}
