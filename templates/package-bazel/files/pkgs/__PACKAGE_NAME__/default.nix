{
  self,
  lib,
  buildBazelPackage,
}:
buildBazelPackage rec {
  pname = "__PACKAGE_NAME__";
  version = "0.0.0-${lib.flox-floxpkgs.getRev self}";
  src = self; # + "/src";

  bazelTarget = "main:__PACKAGE_NAME__";
  buildAttrs = {
    installPhase = ''
      mkdir -p "$out/bin"
      install bazel-out/k8-fastbuild/bin/main/__PACKAGE_NAME__ "$out/bin"
    '';
  };
  fetchAttrs = {
    sha256 = lib.fakeSha256;
    #sha256 = "<real-sha256-here>";
  };
  meta.description = "an example flox package";
}
