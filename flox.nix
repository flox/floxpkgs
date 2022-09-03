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
    stabilities = {
      stable = inputs.nixpkgs.stable;
      staging = inputs.nixpkgs.staging;
      unstable = inputs.nixpkgs.unstable;
      default = inputs.nixpkgs.stable;
    };

    extraPlugins =
      [
        (inputs.capacitor.plugins.allLocalResources {})
        (inputs.capacitor.plugins.templates {})
        (inputs.capacitor.plugins.nixpkgs)
      ]
      ++ (builtins.map
        (system: (inputs.flox-extras.plugins.catalog {
          catalogDirectory = inputs.catalog + "/render/${system}";
          inherit system;
          path = ["floxpkgs"];
        })) ["x86_64-linux" "x86_64-darwin" "aarch64-darwin"]);
  };

  passthru.catalog =
    lib.genAttrs
    self.__reflect.systems
    (
      system:
        lib.recurseIntoAttrs
        (
          lib.genAttrs
          self.__reflect.stabilities
          (
            stability: (lib.recurseIntoAttrs ({nixpkgs = (inputs.nixpkgs.catalog.${system} or {}).${stability} or {};}))
          )
        )
    );
}
