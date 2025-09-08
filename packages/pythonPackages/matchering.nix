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
  pname = "matchering";
  version = "2.0.6";
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
