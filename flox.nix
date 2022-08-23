{inputs, ...}:
# Define package set structure
{
  # Limit the systems to fewer or more than default by ucommenting
  packages = {
    builtfilter = {inputs, ...}: inputs.builtfilter.legacyPackages.builtfilter-rs;
  };

  config = {
    stabilities = {
      stable = inputs.nixpkgs.stable;
      staging = inputs.nixpkgs.staging;
      unstable = inputs.nixpkgs.unstable;
      default = inputs.nixpkgs.stable;
    };

    extraPlugins = [
      (inputs.flox-extras.plugins.catalog {catalogDirectory = inputs.catalog + "/render/x86_64-linux"; system = "x86_64-linux";})
      (inputs.capacitor.plugins.allLocalResources {})
      (inputs.capacitor.plugins.templates {})
      (inputs.capacitor.plugins.nixpkgs)
    ];
  };
}
