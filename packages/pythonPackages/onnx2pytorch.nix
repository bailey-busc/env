{
  lib,
  buildPythonPackage,
  fetchPypi,
  pythonOlder,
  setuptools,
  numpy,
  scipy,
  soundfile,
  resampy,
  statsmodels,
}:

buildPythonPackage rec {
  pname = "onnx2pytorch";
  version = "0.5.1";
  pyproject = true;
  disabled = pythonOlder "3.8";

  src = fetchPypi {
    inherit pname version;
    hash = "";
  };

  nativeBuildInputs = [
    setuptools
  ];

  propagatedBuildInputs = [
    numpy
    scipy
    soundfile
    resampy
    statsmodels
  ];

  doCheck = false;

  pythonImportsCheck = [ "matchering" ];

  meta = with lib; {
    description = '''';
    homepage = "https://github.com/sergree/matchering";
    license = licenses.mit;
  };
}
