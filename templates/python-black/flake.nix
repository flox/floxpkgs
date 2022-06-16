rec {
  description = "Python Black example template";
  inputs.capacitor.url = "git+ssh://git@github.com/flox/capacitor";
  inputs.capacitor.inputs.root.follows = "/";
  inputs.capacitor.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixpkgs.url = "git+ssh://git@github.com/flox/nixpkgs-flox";

  nixConfig.bash-prompt = "[flox]\\e\[38;5;172mλ \\e\[m";

  outputs = _: _.capacitor _ ({auto,...}: {
    devShells.default = {system,...}: auto.usingWith inputs ./flox.toml _.nixpkgs.legacyPackages.${system}.stable;
  });
}
