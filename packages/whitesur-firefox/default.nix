# whitesur-firefox-theme.nix
{
  lib,
  stdenv,
  fetchFromGitHub,
  ...
}:
stdenv.mkDerivation rec {
  pname = "whitesur-firefox-theme";
  version = "2024-06-14";

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "WhiteSur-gtk-theme";
    rev = version;
    sha256 = "";
  };

  installPhase = ''
    mkdir -p $out/share/firefox-themes/{WhiteSur,Monterey}

    cp -r $src/src/other/firefox/WhiteSur/* $out/share/firefox-themes/WhiteSur/
    cp -r $src/src/other/firefox/Monterey/* $out/share/firefox-themes/Monterey/

    cp -r $src/src/other/firefox/common/* $out/share/firefox-themes/WhiteSur/
    cp -r $src/src/other/firefox/common/* $out/share/firefox-themes/Monterey/

    cp $src/src/other/firefox/*.css $out/share/firefox-themes/

    # Create the installer script
    mkdir -p $out/bin
    substitute ${./install.sh} $out/bin/install-whitesur-firefox \
      --subst-var out
    chmod +x $out/bin/install-whitesur-firefox
  '';

  meta = with lib; {
    description = "MacOS Safari like theme for Firefox";
    homepage = "https://github.com/vinceliuice/WhiteSur-gtk-theme";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "install-whitesur-firefox";
  };
}
