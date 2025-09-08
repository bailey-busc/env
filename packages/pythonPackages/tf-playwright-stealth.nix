{
  lib,
  buildPythonPackage,
  fetchPypi,
  playwright,
  pythonOlder,
  setuptools,
}:

buildPythonPackage rec {
  pname = "tf-playwright-stealth";
  version = "1.1.2";
  pyproject = true;

  disabled = pythonOlder "3.8";

  src = fetchPypi {
    inherit pname version;
    sha256 = "";
  };

  nativeBuildInputs = [ setuptools ];

  propagatedBuildInputs = [ playwright ];

  # Tests require Chromium binary
  doCheck = false;

  pythonImportsCheck = [ "playwright_stealth" ];

  meta = with lib; {
    description = "Playwright stealth";
    homepage = "https://github.com/tinyfish-io/tf-playwright-stealth";
    license = licenses.mit;
  };
}
