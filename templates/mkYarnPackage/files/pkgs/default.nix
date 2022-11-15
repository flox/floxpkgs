{
  self,
  mkYarnPackage,
  inputs,
}: let
  pname = "my-package";
  version = "0.0.0-${inputs.flox-flxopkgs.lib.getRev self}";
  src = self; # + "/src";
in
  mkYarnPackage {
    inherit pname version src;
    packageJSON = src + "/package.json";
    yarnLock = src + "/yarn.lock";

    buildPhase = ''
      # example yarn --offline build
    '';

    installPhase = ''
      # example cp -R deps/${pname}/dist $out
    '';

    # example distPhase = "true";
  }
