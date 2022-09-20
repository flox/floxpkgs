{python3Packages}:
python3Packages.buildPythonPackage {
  pname = "my-package";
  version = "0.0.0";
  src = self; # + "/src";

  # Add Python modules needed by your package here
  propagatedBuildInputs = with python3Packages; [
    requests
  ];
}
