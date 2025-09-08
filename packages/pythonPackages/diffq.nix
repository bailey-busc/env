{
  lib,
  buildPythonPackage,
  pythonOlder,
  fetchPypi,
  setuptools,
  wheel,
  cython,
  numpy,
  torch,
}:

buildPythonPackage rec {
  pname = "diffq";
  version = "0.2.4";
  pyproject = true;
  disabled = pythonOlder "3.7";

  src = fetchPypi {
    inherit pname version;
    hash = "";
  };

  nativeBuildInputs = [
    setuptools
    wheel
    cython
  ];

  propagatedBuildInputs = [
    cython
    torch
    numpy
  ];

  doCheck = false;

  pythonImportsCheck = [ "diffq" ];

  meta = with lib; {
    description = ''
      DiffQ performs differentiable quantization using pseudo quantization noise.
      It can automatically tune the number of bits used per weight or group of weights,
      in order to achieve a given trade-off between model size and accuracy.'';
    homepage = "https://github.com/facebookresearch/diffq";
    license = licenses.mit;
  };
}
