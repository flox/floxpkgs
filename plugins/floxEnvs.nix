{
  lib,
  self,
  ...
}: {
  sourceType,
  injectedArgs ? {},
  dir ? sourceType,
}: let
  materialize = lib.capacitor.capacitate.capacitate.materialize;
in
  {
    context,
    ...
  }: let
    floxEnvsMapper = context: {
      namespace,
      system,
      outerPath,
      ...
    }: let
      floxEnvDir = builtins.concatStringsSep "/" ([context.self.outPath dir] ++ outerPath);
      floxNixPath = "${floxEnvDir}/flox.nix";
      catalogPath = "${floxEnvDir}/catalog.json";
    in {
      use = builtins.pathExists floxNixPath;
      # for now just treat flox.nix as a module, although at some point we might want to do something like
      # context.auto.callPackageWith injectedArgs floxNixPath {};
      value = self.lib.mkFloxEnv {
        inherit system;
        modules = [floxNixPath] ++ lib.optional (builtins.pathExists catalogPath) {inherit catalogPath;};
      };
      path = [system] ++ namespace;
    };
    result = materialize (floxEnvsMapper context) (context.closures sourceType);
  in {
    floxEnvs = result;
    devShells = result;
  }
