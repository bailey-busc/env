{
  lib,
  buildPythonPackage,
  pythonOlder,
  fetchPypi,
  pydantic,
  pydantic-core,
  setuptools,
}:
buildPythonPackage rec {
  pname = "hyprpy";
  version = "0.2.0";
  pyproject = true;
  disabled = pythonOlder "3.7";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-f/1aDtAKsknlLvJ62Ek5monCzT/LLcmHg1XaN3r6qpw=";
  };

  build-system = [
    setuptools
  ];

  dependencies = [
    pydantic
    pydantic-core
  ];

  pythonImportsCheck = [
    "hyprpy"
  ];

  meta = {
    description = "Python bindings for Hyprland";
    homepage = "https://github.com/ulinja/hyprpy";
    changelog = "https://github.com/ulinja/hyprpy/blob/${src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
  };
}
