{
  self,
  perlPackages,
  lib,
}:
perlPackages.buildPerlPackage rec {
  pname = "__PACKAGE_NAME__";
  version = "0.0.0-${lib.flox-floxpkgs.getRev self}";
  src = self; # + "/src";

  outputs = ["out"];

  enableParallelBuilding = true;
  meta.description = "An example of flox package.";
  meta.mainProgram = "__PACKAGE_NAME__";
}
