# Filesystem utilities ripped from snowfall-lib and others
{
  inputs,
  lib,
  mapConcatAttrsToList ? inputs.self.lib.attrs.mapConcatAttrsToList,
  hasFileExtension ? inputs.self.lib.path.hasFileExtension,
  ...
}:
let
  inherit (lib) mapAttrsToList filterAttrs;
  inherit (builtins)
    readDir
    pathExists
    filter
    baseNameOf
    ;
in
rec {
  ## Matchers for file kinds. These are often used with `readDir`.
  ## Example Usage:
  ## ```nix
  ## isFileKind "directory"
  ## ```
  ## Result:
  ## ```nix
  ## false
  ## ```
  #@ String -> Bool
  isFileKind = kind: kind == "regular";
  isSymlinkKind = kind: kind == "symlink";
  isDirectoryKind = kind: kind == "directory";
  isUnknownKind = kind: kind == "unknown";

  isNix = hasFileExtension "nix";
  isDefaultNix = path: baseNameOf path == "default.nix";
  isNonDefaultNix = path: (isNix path) && !(isDefaultNix path);

  ## Get a file path relative to this flake.
  ## Example Usage:
  ## ```nix
  ## get-file "systems"
  ## ```
  ## Result:
  ## ```nix
  ## "/user-source/systems"
  ## ```
  #@ String -> String
  getFile = path: "${inputs.self}/${path}";

  ## Safely read from a directory if it exists.
  ## Example Usage:
  ## ```nix
  ## safeReadDirectory ./some/path
  ## ```
  ## Result:
  ## ```nix
  ## { "my-file.txt" = "regular"; }
  ## ```
  #@ Path -> Attrs
  safeReadDirectory = path: if pathExists path then readDir path else { };

  ## Get directories at a given path.
  ## Example Usage:
  ## ```nix
  ## get-directories ./something
  ## ```
  ## Result:
  ## ```nix
  ## [ "./something/a-directory" ]
  ## ```
  #@ Path -> [Path]
  getDirectories =
    path:
    safeReadDirectory path
    |> filterAttrs (_: isDirectoryKind)
    |> mapAttrsToList (name: _: "${path}/${name}");

  ## Get files at a given path.
  ## Example Usage:
  ## ```nix
  ## get-files ./something
  ## ```
  ## Result:
  ## ```nix
  ## [ "./something/a-file" ]
  ## ```
  #@ Path -> [Path]
  getFiles =
    path:
    safeReadDirectory path
    |> filterAttrs (_: isFileKind)
    |> mapAttrsToList (name: _: "${path}/${name}");

  ## Get files at a given path, traversing any directories within.
  ## Example Usage:
  ## ```nix
  ## get-files-recursive ./something
  ## ```
  ## Result:
  ## ```nix
  ## [ "./something/some-directory/a-file" ]
  ## ```
  #@ Path -> [Path]
  getFilesRecursive =
    path:
    safeReadDirectory path
    |> filterAttrs (name: kind: (isFileKind kind) || (isDirectoryKind kind))
    |> mapConcatAttrsToList (
      name: kind:
      let
        path' = "${path}/${name}";
      in
      if isDirectoryKind kind then getFilesRecursive path' else path'
    );

  ## Get nix files at a given path.
  ## Example Usage:
  ## ```nix
  ## get-nix-files "./something"
  ## ```
  ## Result:
  ## ```nix
  ## [ "./something/a.nix" ]
  ## ```
  #@ Path -> [Path]
  getNixFiles = path: getFiles path |> filter isNix;

  ## Get nix files at a given path, traversing any directories within.
  ## Example Usage:
  ## ```nix
  ## get-nix-files "./something"
  ## ```
  ## Result:
  ## ```nix
  ## [ "./something/a.nix" ]
  ## ```
  #@ Path -> [Path]
  getNixFilesRecursive = path: getFilesRecursive path |> filter isNix;

  ## Get nix files at a given path named "default.nix".
  ## Example Usage:
  ## ```nix
  ## get-default-nix-files "./something"
  ## ```
  ## Result:
  ## ```nix
  ## [ "./something/default.nix" ]
  ## ```
  #@ Path -> [Path]
  getDefaultNixFiles = path: getFiles path |> filter isDefaultNix;

  ## Get nix files at a given path named "default.nix", traversing any directories within.
  ## Example Usage:
  ## ```nix
  ## get-default-nix-files-recursive "./something"
  ## ```
  ## Result:
  ## ```nix
  ## [ "./something/some-directory/default.nix" ]
  ## ```
  #@ Path -> [Path]
  getDefaultNixFilesRecursive = path: getFilesRecursive path |> filter isDefaultNix;

  ## Get nix files at a given path not named "default.nix".
  ## Example Usage:
  ## ```nix
  ## getNonDefaultNixFiles "./something"
  ## ```
  ## Result:
  ## ```nix
  ## [ "./something/a.nix" ]
  ## ```
  #@ Path -> [Path]
  getNonDefaultNixFiles = path: getFiles path |> filter isNonDefaultNix;

  ## Get nix files at a given path not named "default.nix", traversing any directories within.
  ## Example Usage:
  ## ```nix
  ## get-non-default-nix-files-recursive "./something"
  ## ```
  ## Result:
  ## ```nix
  ## [ "./something/some-directory/a.nix" ]
  ## ```
  #@ Path -> [Path]
  getNonDefaultNixFilesRecursive = path: getFilesRecursive path |> filter isNonDefaultNix;
}
