{mkYarnPackage}: let
  pname = "my-package";
  version = "0.0.0";
in
  mkYarnPackage {
    inherit pname version;
    src = ../.;
    packageJSON = ../package.json;
    yarnLock = ../yarn.lock;

    buildPhase = ''
      yarn --offline build
    '';

    installPhase = ''
      cp -R deps/${pname}/dist $out
    '';

    distPhase = "true";
  }
