{self, mkYarnPackage}: let
  pname = "my-package";
  version = "0.0.0";
  src = self; # + "/src";
in
  mkYarnPackage {
    inherit pname version src;
    packageJSON = src + "/package.json";
    yarnLock = src + "../yarn.lock";

    buildPhase = ''
      yarn --offline build
    '';

    installPhase = ''
      cp -R deps/${pname}/dist $out
    '';

    distPhase = "true";
  }
