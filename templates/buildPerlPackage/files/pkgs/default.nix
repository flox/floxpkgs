{
  self,
  lib,
  perlPackages,
  withRev
}:
perlPackages.buildPerlPackage rec {
  pname = withRev "my-package";
  version = "0.0.0";
  src = self; # + "/src";

  outputs = ["out"];

  enableParallelBuilding = true;
}
