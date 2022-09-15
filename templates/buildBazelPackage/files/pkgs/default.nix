{
  lib,
  buildBazelPackage,
}:
buildBazelPackage rec {
  pname = "my-package";
  version = "0.0.0";
  src = ../.;
  bazelTarget = "main:my-package";
  buildAttrs = {
    installPhase = ''
      mkdir -p "$out/bin"
      install bazel-out/k8-fastbuild/bin/main/my-package "$out/bin"
    '';
  };
  fetchAttrs = {
    sha256 = lib.fakeSha256;
    #sha256 = "<real-sha256-here>";
  };
}
