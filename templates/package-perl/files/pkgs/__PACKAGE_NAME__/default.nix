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
  meta.description = "an example flox package";
}
