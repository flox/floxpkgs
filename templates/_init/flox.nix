{
  self,
  inputs,
  lib,
  ...
}:
# Define package set structure
{

  # Template Configuration:
  # DO NOT EDIT
  config.extraPlugins = [
      (
        inputs.flox-extras.plugins.catalog {
          catalogDirectory = self.outPath + "/catalog";
        }
      )
      (inputs.capacitor.plugins.allLocalResources {})
    ];
}
