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
        }
      )
      (inputs.capacitor.plugins.allLocalResources {})
    ];
}
