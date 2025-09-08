{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  matplotlib,
  pandas,
  numpy,
  scipy,
  scikit-learn,
  setuptools,
}:

buildPythonPackage rec {
  pname = "dora";
  version = "0.0.5";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "NathanEpstein";
    repo = "Dora";
    rev = "8e62f86fecbbaaf61e5f12b6ee7a6a77c0aec860";
    hash = "";
  };

  nativeBuildInputs = [ setuptools ];

  propagatedBuildInputs = [
    matplotlib
    pandas
    numpy
    scipy
    scikit-learn
  ];

  doCheck = false; # No tests lmao

  pythonImportsCheck = [ "Dora" ];

  meta = with lib; {
    description = "Tools for exploratory data analysis in Python";
    homepage = "https://github.com/NathanEpstein/Dora";
    license = licenses.mit;
  };
}
