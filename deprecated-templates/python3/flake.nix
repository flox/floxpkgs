{
  description = "Python 3 template";
  inputs.capacitor.url = "git+ssh://git@github.com/flox/capacitor";
  inputs.capacitor.inputs.root.follows = "/";
  inputs.nixpkgs.follows = "capacitor/nixpkgs";
  nixConfig.bash-prompt = "[flox] \\[\\033[38;5;172m\\]λ \\[\\033[0m\\]";

  outputs = _: let
    lib = import (_.capacitor + "/lib/customisation.nix") _.capacitor _;
  in
    _.capacitor _ ({auto, ...}: {
      devShells = p:
        auto.using {
          default = ./flox.toml;
        }
        p.pkgs;
    });
}
