{
  self,
  inputs,
  lib,
  ...
}:
# Define package set structure
{

  config.owner = "USER"; # < change this value to match your namespace

  # Template Configuration:
  # DO NOT EDIT
  config.extraPlugins = [
      (
        inputs.flox-extras.plugins.allCatalogs {
          catalogsDirectory = self.outPath + "/catalog";
          path = [self.__reflect.finalFlake.config.owner];
        }
      )
    ];
  passthru.catalog =
    lib.foldl
    lib.recursiveUpdate
    {}
    (map (flake: flake.catalog) [
      inputs.floxpkgs
    ]);
}
