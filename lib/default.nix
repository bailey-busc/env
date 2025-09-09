{
  lib,
  inputs,
  self,
  ...
}@args:
let
  inherit (builtins)
    all
    attrNames
    concatMap
    elem
    functionArgs
    isAttrs
    isFunction
    readDir
    ;
  inherit (lib)
    filterAttrs
    flip
    foldl'
    genAttrs
    last
    mapAttrs
    mapAttrs'
    nameValuePair
    recursiveUpdate
    splitString
    toLower
    ;

  assetsGit =
    (import "${self}/data" { inherit (inputs.nixpkgs.legacyPackages.x86_64-linux) fetchgit; }).assets;
in
rec {
  # Import home-manager library functions
  home-manager = inputs.home-manager.lib.hm;
  inherit (home-manager) generators;

  attrs = import ./attrs.nix args;
  flake = import ./flake.nix args;
  fp = import ./fp.nix args;
  fs = import ./fs.nix args;
  maybe = import ./maybe.nix args;
  modules = import ./modules.nix args;
  path = import ./path.nix args;
  testing = import ./testing.nix args;
  xml = import ./xml.nix args;

  # Asset paths for icons and wallpapers
  assets = {
    # Icon paths
    icons = {
      github = toString ../data/icons/github.png;
    };

    # Wallpaper paths with automatic file discovery
    wallpapers =
      let
        wallpaperDir = "${assetsGit}/wallpapers";
        # List of supported image file extensions
        validExtensions = [
          "jpg"
          "jpeg"
          "png"
          "gif"
          "webp"
        ];
        # Get list of files in wallpapers directory
        files = readDir wallpaperDir;
        # Helper to strip multiple file extensions
        removeExtensions = name: foldl' (acc: ext: lib.removeSuffix ".${ext}" acc) name validExtensions;
        # Filter for valid image files
        imageFiles = filterAttrs (
          name: _:
          let
            ext = toLower (last (splitString "." name));
          in
          elem ext validExtensions
        ) files;
      in
      # Create attribute set mapping stripped names to full paths
      lib.mapAttrs' (
        name: _: nameValuePair (removeExtensions name) (toString (wallpaperDir + "/${name}"))
      ) imageFiles;
  };

  in' = flip builtins.elem;
  notIn = xs: x: !(builtins.elem x xs);
  not = x: !x;

  # Merge multiple attribute sets recursively
  mergeAttrs' = foldl' recursiveUpdate { };

  # Map a function over attribute values
  mapAttrVals = f: mapAttrs (_: f);

  concatMapAttrsToList = fn: attrs: attrNames attrs |> concatMap (name: fn name attrs.${name});

  # Map a function over attribute names
  mapAttrNames = fn: mapAttrs' (name: value: nameValuePair (fn name value) value);
  mapAttrNames' = fn: mapAttrs' (name: value: nameValuePair (fn name) value);

  # Additional filtering functions
  filterNullAttrs = filterAttrVals notNull;
  filterAttrVals = pred: filterAttrs (_: v: pred v);
  filterAttrNames = pred: filterAttrs (n: _: pred n);

  filterNulls = builtins.filter notNull;

  # Map over filtered items in a list
  filterMap = pred: fn: map (v: if pred v then fn v else v);

  # Map over filtered attribute sets
  filterMapAttrs = pred: fn: mapAttrs (k: v: if pred k v then fn k v else v);
  filterMapAttrVals = pred: fn: mapAttrVals (v: if pred v then fn v else v);
  filterMapAttrNames = pred: fn: mapAttrNames (k: if pred k then fn k else k);

  hasAttrs = attrs: all (flip builtins.hasAttr attrs);

  genAttrs' = flip genAttrs;

  # Generate empty attribute set with given keys
  genEmptyAttrs = genAttrs' (_: { });

  # Function composition helpers
  compose =
    fx: gx: x:
    gx (fx x);

  argPassthroughChar = "\"$${@}\"";

  joinLines = lib.concatStringsSep "\n";
  isNull = value: value == null;
  notNull = value: value != null;

  optional' = pred: value: if pred then value else null;

  makeCustomizable =
    fnName: f:
    let
      makeCustomizable' = makeCustomizable fnName;
      # Creates a functor with the same arguments as f
      mirrorArgs = lib.mirrorFunctionArgs f;
    in
    mirrorArgs (
      origArgs:
      let
        result = f origArgs;

        # Changes the original arguments with (potentially a function that returns) a set of new attributes
        overrideWith = newArgs: origArgs // (if isFunction newArgs then newArgs origArgs else newArgs);

        # Re-call the function but with different arguments
        overrideArgs = mirrorArgs (newArgs: makeCustomizable' f (overrideWith newArgs));
        # Change the result of the function call by applying g to it
        overrideResult = g: makeCustomizable' (mirrorArgs (args: g (f args))) origArgs;
      in
      if isAttrs result then
        result
        // {
          ${fnName} = overrideArgs;
          ${if result ? "${fnName}Attrs" then "${fnName}Attrs" else null} =
            fdrv: overrideResult (x: x."${fnName}Attrs" fdrv);
        }
      else if isFunction result then
        # Transform the result into a functor while propagating its arguments
        lib.setFunctionArgs result (functionArgs result)
        // {
          ${fnName} = overrideArgs;
        }
      else
        result
    );
}
