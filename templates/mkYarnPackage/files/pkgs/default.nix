{self, mkYarnPackage, withRev}: let
  pname = "my-package";
  version = withRev "0.0.0";
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
