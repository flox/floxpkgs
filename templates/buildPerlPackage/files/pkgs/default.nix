{
  lib,
  perlPackages,
}:
perlPackages.buildPerlPackage rec {
  pname = "my-package";
  version = "0.0.0";

  src = ../.;

  outputs = ["out"];

  enableParallelBuilding = true;
}
