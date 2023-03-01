{
  lib,
  self,
  ...
}: {
  injectedArgs ? {},
}: {context, ...}: let
  floxEnvDir = context.self.outPath;
  floxNixPath = "${floxEnvDir}/flox.nix";
  catalogPath = "${floxEnvDir}/catalog.json";
  namespace = ["default"];
  result = lib.genAttrs context.systems (system: {
    default = self.lib.mkFloxEnv {
      inherit context system namespace;
      modules = [floxNixPath] ++ lib.optional (builtins.pathExists catalogPath) {inherit catalogPath;};
    };
  });
in
  {
    floxEnvs = if builtins.pathExists floxNixPath then result else {};
    devShells = if builtins.pathExists floxNixPath then result else {};
  }
