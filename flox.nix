{inputs, ...}:
# Define package set structure
{
  # Limit the systems to fewer or more than default by ucommenting
  packages = {
   
  };

  config = {
    stabilities = {
      stable = inputs.nixpkgs.stable;
      staging = inputs.nixpkgs.staging;
      unstable = inputs.nixpkgs.unstable;
      default = inputs.nixpkgs.stable;
    };

    extraPlugins = [
      (inputs.capacitor.plugins.allLocalResources {})
      (inputs.capacitor.plugins.templates {})
      (inputs.capacitor.plugins.nixpkgs)
    ];
  };
}
