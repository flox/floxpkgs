{
  self,
  perlPackages,
  lib,
}:
perlPackages.buildPerlPackage rec {
  pname = "my-package";
  version = "0.0.0-${lib.flox-floxpkgs.getRev self}";
  src = self; # + "/src";

  outputs = ["out"];

  enableParallelBuilding = true;
}
