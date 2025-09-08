{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    getExe'
    getExe
    mkIf
    mkMerge
    ;
in
{
  home = {
    sessionVariables = mkMerge [
      (mkIf config.programs.doom-emacs.enable {
        EDITOR = "${getExe' config.programs.doom-emacs.finalDoomPackage "emacsclient"} -nw";
      })
      (mkIf config.programs.zed-editor.enable {
        VISUAL = "${getExe config.programs.zed-editor.package} --wait";
      })
    ];
    packages = with pkgs; [
      hyperfine
      icu
      less
      libkrb5
      ncdu
      openssl
      pass
      tokei
      zlib
      # Random shit that idk where to put otherwise
      grip-search
      # Common build-related dependencies
      #
      gcc
      pkg-config
      gnumake
      kdePackages.qtdeclarative
    ];
  };

  editorconfig = {
    enable = true;
    settings."*" = {
      charset = "utf-8";
      end_of_line = "lf";
      trim_trailing_whitespace = true;
      insert_final_newline = true;
      max_line_width = 78;
      indent_style = "space";
      indent_size = 4;
    };
  };
}
