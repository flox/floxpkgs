{
  self,
  python3Packages,
  lib,
}:
python3Packages.buildPythonApplication {
  pname = "__PACKAGE_NAME__";
  version = "0.0.0-${lib.flox-floxpkgs.getRev self}";
  src = self;
  PIP_DISABLE_PIP_VERSION_CHECK = 1;
  # Add Python modules needed by your package here
  propagatedBuildInputs = with python3Packages; [
    requests
  ];
  meta.description = "an example flox package";
}
