{
  description = "Template using specific versions";

  inputs.capacitor.url = "git+ssh://git@github.com/flox/capacitor?ref=v0";
  inputs.capacitor.inputs.root.follows = "/";

  inputs.nixpkgs.url = "git+ssh://git@github.com/flox/nixpkgs-flox";

  inputs.floxpkgs.url = "git+ssh://git@github.com/flox/floxpkgs";
  inputs.floxpkgs.inputs.capacitor.follows = "capacitor";
  inputs.floxpkgs.inputs.nixpkgs.follows = "nixpkgs";
  inputs.floxpkgs.inputs.default.follows = "/";

  # TODO: preferred method below would only need this. (https://github.com/NixOS/nix/issues/5790)
  # inputs.floxpkgs.url = "git+ssh://git@github.com/flox/floxpkgs";
  # inputs.floxpkgs.inputs.capacitor.inputs.root.follows = "/";

  nixConfig.bash-prompt = "[flox] \\[\\033[38;5;172m\\]λ \\[\\033[0m\\]";

  outputs = _:
    _.capacitor _ ({ lib, inputs, self, ... }: {
      devShells.default = inputs.floxpkgs.lib.mkFloxShell ./flox.toml self.__pins;
      
      config.stabilities = {
        stable = inputs.nixpkgs.stable;
        staging = inputs.nixpkgs.staging;
        unstable = inputs.nixpkgs.unstable;
        default = inputs.nixpkgs.stable;
      };

      # packages.default = {nixpkgs',...}: nixpkgs'.hello;


      # AUTO-MANAGED AFTER THIS POINT ##################################
      # AUTO-MANAGED AFTER THIS POINT ##################################
      # AUTO-MANAGED AFTER THIS POINT ##################################
      passthru = {
        __pins.versions = {
        };
        __pins.vscode-extensions = [
        ];
      };
    });
}
