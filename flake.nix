rec {
  inputs.capacitor.url = "git+ssh://git@github.com/flox/capacitor";

  outputs = {self, capacitor, ...} @ args: capacitor args ({auto,...}: {
    packages = auto.automaticPkgsWith inputs ./pkgs;
    legacyPackages = capacitor.inputs.nixpkgs.legacyPackages;
  });
}
