{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
}:

buildPythonPackage rec {
  pname = "kthread";
  version = "0.2.3";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "";
  };

  nativeBuildInputs = [
    setuptools
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
