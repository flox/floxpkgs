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
      (inputs.flox-extras.plugins.catalog {
        catalogDirectory = inputs.catalog + "/catalog";
      })
      (inputs.capacitor.plugins.templates {})
    ];
  };

  # reexport of capacitor
  passthru.capacitor = inputs.capacitor;
  # reexport of flox-extras
  # TODO: integrate into floxpkgs
  passthru.flox-extras = inputs.flox-extras;
}
