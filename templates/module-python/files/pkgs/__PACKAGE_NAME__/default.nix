{
  self,
  python3Packages,
}:
python3Packages.buildPythonPackage {
  pname = "__PACKAGE_NAME__";
  version = "0.0.0";
  src = self;
  PIP_DISABLE_PIP_VERSION_CHECK = 1;
  # Add Python modules needed by your package here
  propagatedBuildInputs = with python3Packages; [
    requests
  ];
  meta.description = "an example flox package";
}
