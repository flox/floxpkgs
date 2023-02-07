# Note, to use this template you will also need to run the command `flox run github:flox-examples/gradle2nix`
# from the root directory of the project.
# Running this utility will produce the `gradle-env.nix` and `gradle-env.json` needed for `flox build` and `flox develop`
# to succeed with this project. See the How-to Guides/Language Guides section of https://beta.floxdev.com/docs/ for
# more details
{
  self,
  callPackage,
  pkgs,
  ...
}: let
  buildGradle = callPackage ../../gradle-env.nix {};
  src = self;
in
  buildGradle {
    pname = "__PACKAGE_NAME__";
    nativeBuildInputs = with pkgs; [makeWrapper openjdk];
    envSpec = ../../gradle-env.json;
    src = self;
    gradleFlags = ["distTar"];

    installPhase = ''
      ls -al app/build
      mkdir $out
      pushd app/build/distributions
      tar -xf *.tar
      cp -r */* $out
      wrapProgram $out/bin/app --prefix PATH : ${pkgs.openjdk}/bin
      popd
    '';
    meta.description = "an example flox package";
  }
