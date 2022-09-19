{
  self,
  inputs,
  lib,
  ...
}:
# Define package set structure
{
  # Limit the systems to fewer or more than default by ucommenting
  packages = {
    builtfilter = {inputs, ...}: inputs.builtfilter.legacyPackages.builtfilter-rs;
  };

  config = {
    extraPlugins = [
      (inputs.capacitor.plugins.allLocalResources {})
      (inputs.capacitor.plugins.templates {})
      (inputs.capacitor.plugins.nixpkgs)
      (inputs.flox-extras.plugins.catalog {
        catalogDirectory = inputs.catalog + "/render";
        path = ["floxpkgs"];
      })
    ];
  };
}
