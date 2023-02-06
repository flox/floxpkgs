{
  self,
  stdenv,
  jdk,
  ant,
  makeWrapper,
  lib,
}:
stdenv.mkDerivation rec {
  pname = "__PACKAGE_NAME__";
  version = "0.0.0-${lib.flox-floxpkgs.getRev self}";
  src = self; # + "/src";
  nativeBuildInputs = [ant jdk makeWrapper];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    ant
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share/${pname}
    mv target/${pname}.jar $out/share/${pname}
    makeWrapper ${jdk}/bin/java $out/bin/${pname} \
    --add-flags "-jar $out/share/${pname}/${pname}.jar"
    runHook postInstall

  '';
  meta.description = "An example of flox package.";
  meta.mainProgram = "__PACKAGE_NAME__";
}
