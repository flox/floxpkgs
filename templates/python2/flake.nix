rec {
  description = "Python 2 template";
  inputs.capacitor.url = "git+ssh://git@github.com/flox/capacitor";
  inputs.nixpkgs.url = "github:flox/nixpkgs/unstable";
  nixConfig.bash-prompt = "[flox]\\e\[38;5;172mλ \\e\[m";

  outputs = {self, ...} @ args: let
    inherit (args.capacitor.lib.customisation args inputs) using automaticPkgs;
  in
    {
      devShells = args.nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-darwin"] (
        system:
          using args.nixpkgs.legacyPackages.${system} {
            default = ./flox.toml;
          }
      );
    }
    // {inherit (args) capacitor;};
}
