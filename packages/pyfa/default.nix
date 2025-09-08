{ appimageTools, fetchurl, ... }:
appimageTools.wrapType2 rec {
  pname = "pyfa";
  version = "2.60.0";
  src = fetchurl {
    url = "https://github.com/pyfa-org/Pyfa/releases/download/v${version}/pyfa-v${version}-linux.AppImage";
    hash = "sha256-bPInlYtsHtLk3AkF8Bf9CgJUAX7zRvdb6qO11MzF3eE=";
  };
  extraPkgs =
    pkgs: with pkgs; [
      libnotify
      pcre2
      # webkitgtk_6_0
    ];
}
