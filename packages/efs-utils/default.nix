{
  stdenv,
  python,
  fetchFromGitHub,
  stunnel,
  lib,
  makeWrapper,
  ...
}:

stdenv.mkDerivation {
  pname = "efs-utils";
  version = "1.31.3";
  src = fetchFromGitHub {
    owner = "aws";
    repo = "efs-utils";
    rev = "f889d068389b569fb19713e1d647387b40702bd9";
    hash = "sha256-lvZqwbIzypBFAIh8trn2sEv9+4G/6yuBWDR7mg79ExE=";
  };

  buildInputs = [ makeWrapper ];

  buildPhase =
    let
      py = python.withPackages (
        ps: with ps; [
          botocore
          configparser
        ]
      );
    in
    ''
      substituteInPlace src/mount_efs/__init__.py \
        --replace "#!/usr/bin/env python3" "#!${lib.getExe py}"
      substituteInPlace src/watchdog/__init__.py \
        --replace "#!/usr/bin/env python3" "#!${lib.getExe py}"
    '';

  installPhase = ''
    mkdir -p $out/{sbin,bin}
    cp src/mount_efs/__init__.py $out/sbin/mount.efs
    cp src/watchdog/__init__.py $out/bin/amazon-efs-mount-watchdog
  '';

  preFixup = ''
    wrapProgram "$out/sbin/mount.efs" --prefix PATH : ${lib.makeBinPath [ stunnel ]}
  '';
}
