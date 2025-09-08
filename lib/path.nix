{
  lib,
  ...
}:
let
  inherit (builtins)
    toString
    baseNameOf
    dirOf
    concatStringsSep
    match
    ;
  inherit (lib) assertMsg last init;

  fileNameRegex = "(.*)\\.(.*)$";
  matchFilename = file: toString file |> match fileNameRegex;
in
rec {
  ## Split a file name and its extension.
  ## Example Usage:
  ## ```nix
  ## splitFileExtension "my-file.md"
  ## ```
  ## Result:
  ## ```nix
  ## [ "my-file" "md" ]
  ## ```
  #@ String -> [String]
  splitFileExtension =
    file:
    let
      matchResult = matchFilename file;
    in
    assert assertMsg (
      matchResult != null
    ) "lib.path.splitFileExtension: File must have an extension to split: ${toString file}";
    matchResult;

  ## Check if a file name has a file extension.
  ## Example Usage:
  ## ```nix
  ## hasAnyFileExtension "my-file.txt"
  ## ```
  ## Result:
  ## ```nix
  ## true
  ## ```
  #@ String -> Bool
  hasAnyFileExtension = file: (matchFilename file) != null;

  ## Get the file extension of a file name.
  ## Example Usage:
  ## ```nix
  ## getFileExtension "my-file.final.txt"
  ## ```
  ## Result:
  ## ```nix
  ## "txt"
  ## ```
  #@ String -> String
  getFileExtension = file: if hasAnyFileExtension file then matchFilename file |> last else "";

  ## Check if a file name has a specific file extension.
  ## Example Usage:
  ## ```nix
  ## hasFileExtension "txt" "my-file.txt"
  ## ```
  ## Result:
  ## ```nix
  ## true
  ## ```
  #@ String -> String -> Bool
  hasFileExtension =
    extension: file: if hasAnyFileExtension file then extension == getFileExtension file else false;

  ## Get the parent directory for a given path.
  ## Example Usage:
  ## ```nix
  ## getParentDirectory "/a/b/c"
  ## ```
  ## Result:
  ## ```nix
  ## "/a/b"
  ## ```
  #@ Path -> Path
  getParentDirectory = path: dirOf path |> baseNameOf;

  ## Get the file name of a path without its extension.
  ## Example Usage:
  ## ```nix
  ## getFileNameWithoutExtension ./some-directory/my-file.pdf
  ## ```
  ## Result:
  ## ```nix
  ## "my-file"
  ## ```
  #@ Path -> String
  getFileNameWithoutExtension =
    path:
    let
      fileName = baseNameOf path;
    in
    if hasAnyFileExtension fileName then
      concatStringsSep "" (init (splitFileExtension fileName))
    else
      fileName;
}
