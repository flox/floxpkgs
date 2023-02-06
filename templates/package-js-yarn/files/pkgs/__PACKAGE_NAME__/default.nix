{
  self,
  mkYarnPackage,
  lib,
}: let
  pname = "__PACKAGE_NAME__";
  version = "0.0.0-${lib.flox-floxpkgs.getRev self}";
  src = self;
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
    meta.description = "An example of flox package.";
    meta.mainProgram = "__PACKAGE_NAME__";
  }
