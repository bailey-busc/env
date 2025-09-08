{
  lib,
  symlinkJoin,
  callPackage,
  ...
}:
let
  inherit (lib) getExe;
  programs = {
    # Doing callPackage form because these will eventually move to separate files
    gh-pr-fzf = callPackage (
      {
        writeShellScriptBin,
        fzf,
        gh,
        jq,
        choose,
        ...
      }:
      let
        hub = "${getExe gh} -R $1";
      in
      writeShellScriptBin "gh-pr-fzf" ''
        ${hub} pr list --json number,title,author | \
            ${getExe jq} -r '.[] | "\(.number) | \(.title) | \(.author.login)"' | \
            ${getExe fzf} --preview-window=right:70% --preview "GH_FORCE_TTY=\$FZF_PREVIEW_COLUMNS ${hub} pr view {1}" | \
            ${getExe choose} 0
      ''
    ) { };

  };
in
symlinkJoin {
  name = "automation scripts";
  paths = builtins.attrValues programs;
  passthru = {
    inherit programs;
  };
}
