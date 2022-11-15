{
  self,
  perlPackages,
  inputs,
}:
perlPackages.buildPerlPackage rec {
  pname = "my-package";
  version = "0.0.0-${inputs.flox-flxopkgs.lib.getRev self}";
  src = self; # + "/src";

  outputs = ["out"];

  enableParallelBuilding = true;
}
