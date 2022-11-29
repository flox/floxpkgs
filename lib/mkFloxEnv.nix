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
      (self + "/modules/flox-env.nix")
    ]
    ++ modules;
})
.config
.toplevel
