{
  lib,
  buildBazelPackage,
}:
buildBazelPackage rec {
  # you can git clone https://github.com/bazelbuild/examples
  # and cd into examples/cpp-tutorial/stage1 to use this template
  # with a real bazel project example
  pname = "hello-world";
  version = "0.0.0";
  src = ./.;
  bazelTarget = "main:hello-world";
  buildAttrs = {
    installPhase = ''
      mkdir -p "$out/bin"
      install bazel-out/k8-fastbuild/bin/main/hello-world "$out/bin"
    '';
  };
  fetchAttrs = {
    sha256 = lib.fakeSha256;
    #sha256 = "<real-sha256-here>";
  };
}
