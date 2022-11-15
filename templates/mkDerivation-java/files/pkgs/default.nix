{
  self,
  stdenv,
  jdk,
  ant,
  makeWrapper,
  inputs,
}:
stdenv.mkDerivation rec {
  pname = "my-package";
  version = "0.0.0-${inputs.flox-flxopkgs.lib.getRev self}";
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
}
