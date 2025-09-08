{
  lib,
  stdenv,
  python,
  buildPythonApplication,
  fetchFromGitHub,
  ffmpeg,
  rubberband,
  makeWrapper,
  makeDesktopItem,
}:
let
  inherit (lib) optionals;
  inherit (stdenv) isDarwin;
in
buildPythonApplication rec {
  pname = "ultimatevocalremovergui";
  version = "5.6";

  # Use format = "other" since this app doesn't use setup.py or pyproject.toml
  format = "other";

  src = fetchFromGitHub {
    owner = "Anjok07";
    repo = "ultimatevocalremovergui";
    rev = "v${version}";
    hash = "sha256-2FV7qO40LcyJTrHiWeCzAPvelcgGc+InrsXv9/QGLkA=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = [
    ffmpeg
    rubberband
  ];

  dependencies = (
    with python.pkgs;
    [
      altgraph
      audioread
      certifi
      cffi
      cryptography
      diffq
      dora
      einops
      future
      julius
      kthread
      librosa
      llvmlite
      matchering
      matplotlib
      ml-collections
      natsort
      numpy
      omegaconf
      onnx
      onnx2pytorch
      onnxruntime
      onnxruntime-gpu
      opencv4
      packaging
      pillow
      playsound
      psutil
      pydub
      pydub
      pyglet
      pyperclip
      pyrubberband
      pytorch-lightning
      pyyaml
      requests
      resampy
      samplerate
      scipy
      screeninfo
      setuptools
      soundfile
      soundstretch
      tkinter
      torch
      torchaudio
      torchvision
      tqdm
      urllib3
      wget
      wheel
    ]
    ++ optionals isDarwin [
      pysoundfile
      soundfile
    ]
  );

  # Don't build or configure since this is format = "other"
  dontBuild = true;
  dontConfigure = true;

  # Desktop integration
  desktopItems = [
    (makeDesktopItem {
      name = "ultimatevocalremovergui";
      desktopName = "Ultimate Vocal Remover";
      comment = "GUI for a Vocal Remover that uses Deep Neural Networks";
      exec = "uvr";
      icon = "audio-x-generic";
      categories = [
        "AudioVideo"
        "Audio"
      ];
    })
  ];

  installPhase = ''
    runHook preInstall

    # Install only the necessary application files
    mkdir -p $out/share/ultimatevocalremovergui
    cp -r . $out/share/ultimatevocalremovergui/

    # Create the main executable wrapper
    mkdir -p $out/bin
    makeWrapper ${python.withPackages (_: dependencies)}/bin/python $out/bin/uvr \
      --add-flags "$out/share/ultimatevocalremovergui/UVR.py" \
      --prefix PATH : ${
        lib.makeBinPath [
          ffmpeg
          rubberband
        ]
      }

    # Create convenience symlinks
    ln -s $out/bin/uvr $out/bin/ultimatevocalremovergui
    ln -s $out/bin/uvr $out/bin/UVR

    runHook postInstall
  '';

  # Test that basic imports work
  pythonImportsCheck = [
    "tkinter"
  ];

  meta = with lib; {
    description = "GUI for a Vocal Remover that uses Deep Neural Networks";
    longDescription = ''
      Ultimate Vocal Remover (UVR) is a state-of-the-art source separation tool
      that uses deep neural networks to remove vocals from audio files. It supports
      multiple AI models including MDX-Net, Demucs, and VR Architecture models.

      Features:
      - AI-powered vocal and instrument separation
      - Support for multiple audio formats (MP3, FLAC, WAV, OGG, etc.)
      - Multiple neural network architectures
      - Batch processing capabilities
      - GPU acceleration support (NVIDIA recommended)
      - Cross-platform compatibility
    '';
    homepage = "https://github.com/Anjok07/ultimatevocalremovergui";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "uvr";
  };
}
