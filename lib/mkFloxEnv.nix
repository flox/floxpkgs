{
  lib,
  nixpkgs,
  self,
  #  system,
}: {
  system,
  modules,
  context,
}:
(lib.evalModules {
  modules =
    [
      {
        _module.args = {
          inherit system context;
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
