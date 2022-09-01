{
  inputs.capacitor.url = "git+ssh://git@github.com/flox/capacitor?ref=v0";
  inputs.capacitor.inputs.root.follows = "/";
  inputs.capacitor.inputs.nixpkgs.follows = "nixpkgs/nixpkgs-stable";

  inputs.nixpkgs.url = "git+ssh://git@github.com/flox/nixpkgs-flox";
  inputs.nixpkgs.inputs.capacitor.follows = "capacitor";

  inputs.floxpkgs.url = "git+ssh://git@github.com/flox/floxpkgs";
  inputs.floxpkgs.inputs.capacitor.follows = "capacitor";
  inputs.floxpkgs.inputs.nixpkgs.follows = "nixpkgs";

  nixConfig.bash-prompt = "[flox]\\e\[38;5;172mλ \\e\[m";

  outputs = args @ {capacitor, ...}:
    capacitor args (
      {
        inputs,
        self,
        lib,
        ...
      }: {
        description = "Generic template for any other language";

        devShells.default =
          lib.optionalAttrs
          (builtins.pathExists ./flox.toml)
          (inputs.floxpkgs.lib.mkFloxShell ./flox.toml {});

        config.extraPlugins = [
          (inputs.capacitor.plugins.allLocalResources {})
        ];
      }
    );
}
