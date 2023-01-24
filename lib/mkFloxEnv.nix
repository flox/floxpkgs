{
  lib,
  nixpkgs,
  self,
}: {
  context,
  namespace,
  modules,
  system,
}:
(lib.evalModules {
  modules =
    [
      {
        _module.args = {
          inherit context namespace system;
        };
      }
      (self + "/modules/common.nix")
      (self + "/modules/options.nix")
      (self + "/modules/container.nix")
      (self + "/modules/shells/posix.nix")
    ]
    ++ modules;
})
.config
.toplevel
