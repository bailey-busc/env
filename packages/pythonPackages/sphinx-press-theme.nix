{
  lib,
  python,
  buildPythonPackage,
  fetchPypi,
}:
buildPythonPackage rec {
  pname = "sphinx-press-theme";
  version = "0.9.1";
  pyproject = true;

  src = fetchPypi {
    pname = "sphinx_press_theme";
    inherit version;
    hash = "sha256-FkPe5zZfeDHR05cbOJt8JVZBp6ztdfBoH3FXTjgARs8=";
  };

  build-system = with python.pkgs; [
    setuptools
    wheel
  ];

  dependencies = with python.pkgs; [
    sphinx
  ];

  pythonImportsCheck = [
    "sphinx_press_theme"
  ];

  meta = {
    description = "A Sphinx-doc theme based on Vuepress";
    homepage = "https://pypi.org/project/sphinx-press-theme/";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "sphinx-press-theme";
  };
}
