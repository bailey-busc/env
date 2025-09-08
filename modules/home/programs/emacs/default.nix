{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (pkgs.stdenv) isLinux;
  inherit (pkgs.stdenv.hostPlatform) isx86;
  inherit (lib)
    getExe
    mkIf
    mkMerge
    ;
in
{
  services.emacs = mkIf isLinux {
    enable = true;
    client.enable = true;
    socketActivation.enable = true;
    startWithUserSession = false;
  };
  programs = {
    doom-emacs = {
      enable = true;
      doomDir = inputs.doomconf;
      emacs = pkgs.emacs-pgtk;
      extraPackages =
        epkgs: with epkgs; [
          vterm
          treesit-grammars.with-all-grammars
        ];
      experimentalFetchTree = true;
    };
  };
  home = {
    sessionPath = [ "${config.home.homeDirectory}/.yarn/bin" ];
    sessionVariables.EMACS = getExe config.programs.doom-emacs.finalEmacsPackage;
    packages = (
      with pkgs;
      mkMerge [
        [
          eask-cli
          # Doom dependencies
          # :term vterm
          cmake
          ispell
          (aspellWithDicts (
            dicts: with dicts; [
              en
              en-computers
              en-science
            ]
          ))
          emacs-all-the-icons-fonts

          # Languages
          nodePackages.dockerfile-language-server-nodejs # docker
          nixpkgs-fmt # nix
          llvm # c++
          nodePackages.bash-language-server # bash
          pyright # python
          nixpkgs-fmt # formatting nix files

          sqlite
          git

          pandoc

          # Grammar checker
          languagetool
        ]
        (mkIf isLinux [
          libvterm-neovim
          xdotool
          xclip
          xorg.xwininfo
        ])
        (mkIf isx86 [
          isync
          notmuch
        ])
      ]
    );
  };
}
