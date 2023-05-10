{
  self,
  buildGoModule,
  lib,
}:
buildGoModule {
  pname = "__PACKAGE_NAME__";
  version = "0.0.0-${lib.flox-floxpkgs.getRev self}";
  src = self; # + "/src";
  # vendorSha256 should be set to null if dependencies are vendored. If the dependencies aren't
  # vendored, vendorSha256 must be set to a hash of the content of all dependencies. This hash can
  # be found by setting
  # vendorSha256 = lib.fakeSha256;
  # and then running flox build. The build will fail but output the expected sha, which can then be
  # added here.
  vendorSha256 = null;
  meta.description = "an example flox package";
}
