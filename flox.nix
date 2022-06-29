{inputs, ...}:
# Define package set structure
{
  # Limit the systems to fewer or more than default by ucommenting
  packages = {
    flox = {inputs, lib, ...}: inputs.flox.defaultPackage;
  };

  apps = {
    test = {
      type= "app";
      program = "";
    };
  };
  

  config = {
    systems = [ "x86_64-linux" ];

    stabilities = {
      stable = inputs.nixpkgs.inputs.nixpkgs-stable;
      staging = inputs.nixpkgs.inputs.nixpkgs-staging;
      unstable = inputs.nixpkgs.inputs.nixpkgs-unstable;
      default = inputs.nixpkgs.inputs.nixpkgs-stable;
    };

    extraPlugins = [
      (inputs.capacitor.plugins.allLocalResources {})
      (inputs.capacitor.plugins.templates {})
    ];
  };
}
