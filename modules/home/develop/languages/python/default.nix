{
  config,
  lib,

  pkgs,
  osConfig,
  ...
}:
let
  systemPython = pkgs.python313.withPackages (
    pyPkgs: with pyPkgs; [
      black
      isort
      mypy
      pip
      ptpython
      pygments
      pytest
      setuptools
      virtualenv
    ]
  );
in
lib.mkIf config.env.profiles.dev.enable {
  home = {
    packages = [
      systemPython
    ]
    ++ (with pkgs; [
      ruff
      pipx
      #poetry
    ]);

    sessionVariables.PYTHONSTARTUP = ./ptconfig.py;
  };
  programs = {
    pyenv.enable = true;
    #poetry.enable = true;
  };
}
