rec {
  inputs.capacitor.url = "git+ssh://git@github.com/flox/capacitor";
  inputs.capacitor.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixpkgs.url = "github:flox/nixpkgs/unstable";
  inputs.companypkgs.url = "git+ssh://git@github.com/flox-examples/companypkgs";

  inputs.toml.url = "path:./flox.toml";
  inputs.toml.flake = false;

  nixConfig.bash-prompt = "[flox]\\e\[38;5;172mλ \\e\[m";

  outputs = {self, capacitor, ...} @ args: capacitor args ({auto,...}: {
    devShells = args.nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-darwin"] (system: {
      default = auto.usingWith inputs ./flox.toml (
        args.companypkgs.legacyPackages.${system}
      );
    });
  });
}
