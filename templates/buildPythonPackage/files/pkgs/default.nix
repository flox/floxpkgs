{
  self,
  python3Packages,
  inputs,
}:
python3Packages.buildPythonPackage {
  pname = "my-package";
  version = "0.0.0-${inputs.flox-floxpkgs.lib.getRev self}";
  src = self; # + "/src";
  PIP_DISABLE_PIP_VERSION_CHECK = 1;
  # Add Python modules needed by your package here
  propagatedBuildInputs = with python3Packages; [
    requests
  ];
}
