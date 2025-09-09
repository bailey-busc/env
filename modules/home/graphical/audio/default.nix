{
  pkgs,
  lib,
  self',
  inputs',
  inputs,
  config,
  self,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (config.env) profiles;
in
mkIf profiles.personal.enable {
  home = {
    packages = with pkgs; [
      # :D
      (pkgs.callPackage ./wrapper.nix {
        bitwig-studio-unwrapped = (
          pkgs.callPackage ./bitwig-6.nix {
            src = "${(import "${self}/data" { inherit (pkgs) fetchgit; }).assets}/bws6.deb";
          }
        );
      })
      helm
      helm
      autotalent
      distrho-ports
      # vital
      surge-XT

      #sourcer
      fire
      ninjas2
      vocproc
      mixxx

      #yabridge
      #yabridgectl
      # winetricks
      wineasio
      # wine64
      jalv
      audacity
      playerctl

      inputs'.audio.packages.vital
      # (inputs'.audio.packages.neuralnote.override {
      #   inherit (self'.packages) libonnxruntime-neuralnote;
      #   webkitgtk = pkgs.webkitgtk_4_0;
      # })

      # self'.packages.ultimate-vocal-remover-gui
    ];

    file = {
      ".audio-plugins".source = pkgs.symlinkJoin {
        name = "audio-plugins";
        paths = with pkgs; [
          talentedhack
          distrho-ports
          vital
          fire
          ninjas2
          surge-XT
          autotalent
        ];
      };
    };
  };
  services.playerctld.enable = true;
}
