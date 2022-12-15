{
  lib,
  nixpkgs,
  self,
  #  system,
}: {
  system,
  modules,
  context,
  attrPath,
}:
(lib.evalModules {
  modules =
    [
      {
        _module.args = {
          pkgs = nixpkgs.legacyPackages.${system};
          inherit system self context attrPath;
        };
      }
      (self + "/modules/common.nix")
      (self + "/modules/options.nix")
      (self + "/modules/shells/posix.nix")
    ]
    ++ modules;
})
.config
.toplevel
