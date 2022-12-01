{
  lib,
  nixpkgs,
  self,
  #  system,
}: {
  system,
  modules,
}:
(lib.evalModules {
  modules =
    [
      {
        _module.args = {
          pkgs = nixpkgs.legacyPackages.${system};
          inherit system self;
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
