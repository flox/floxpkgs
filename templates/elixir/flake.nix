{
  description = "Elixir template";

  inputs.capacitor.url = "git+ssh://git@github.com/flox/capacitor?ref=v0";
  inputs.capacitor.inputs.root.follows = "/";
  inputs.capacitor.inputs.nixpkgs.follows = "nixpkgs/nixpkgs-stable";

  inputs.nixpkgs.url = "git+ssh://git@github.com/flox/nixpkgs-flox";
  inputs.nixpkgs.inputs.capacitor.follows = "capacitor";

  inputs.floxpkgs.url = "git+ssh://git@github.com/flox/floxpkgs";
  inputs.floxpkgs.inputs.capacitor.follows = "capacitor";
  inputs.floxpkgs.inputs.nixpkgs.follows = "nixpkgs";

  nixConfig.bash-prompt = "[flox] \\[\\033[38;5;172m\\]λ \\[\\033[0m\\]";

  outputs = args @ {capacitor, ...}:
    capacitor args (
      {
        inputs,
        self,
        lib,
        ...
      }: {
        devShells.default =
          lib.optionalAttrs
          (builtins.pathExists ./flox.toml)
          (inputs.floxpkgs.lib.mkFloxShell ./flox.toml {});

        config = {
          stabilities = {
            stable = inputs.nixpkgs.stable;
            staging = inputs.nixpkgs.staging;
            unstable = inputs.nixpkgs.unstable;
            default = inputs.nixpkgs.stable;
          };
          extraPlugins = [
            (inputs.capacitor.plugins.allLocalResources {})
          ];
        };
      }
    );
}
