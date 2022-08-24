rec {
  inputs.capacitor.url = "git+ssh://git@github.com/flox/capacitor?ref=v0";
  inputs.capacitor.inputs.root.follows = "/";
  
  inputs.flox-extras.url = "git+ssh://git@github.com/flox/flox-extras";
  inputs.flox-extras.inputs.capacitor.follows = "capacitor";

  inputs.catalog.url = "git+ssh://git@github.com/flox/floxpkgs?ref=publish";
  inputs.catalog.flake = false;

  inputs.nixpkgs.url = "git+ssh://git@github.com/flox/nixpkgs-flox";

  # Declaration of external resources
  # =================================

  inputs.flox.url = "git+ssh://git@github.com/flox/flox?ref=tng";
  inputs.flox.flake = false;

  inputs.nix-editor.url = "github:vlinkz/nix-editor";
  inputs.nix-editor.inputs.nixpkgs.follows = "nixpkgs";
  # nix has a bug where it can't add a follows two inputs deep, so add this hack to make naersk
  # follow nixpkgs
  inputs.naersk.url = "github:nix-community/naersk";
  inputs.naersk.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nix-editor.inputs.naersk.follows = "naersk";

  inputs.devshell.url = "github:numtide/devshell";
  inputs.devshell.inputs.nixpkgs.follows = "nixpkgs";
  inputs.mach-nix.url = "github:DavHau/mach-nix";
  inputs.mach-nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.mach-nix.inputs.pypi-deps-db.follows = "pypi-deps-db";
  inputs.pypi-deps-db.url = "github:DavHau/pypi-deps-db";
  inputs.pypi-deps-db.flake = false;
  inputs.builtfilter.url = "git+ssh://git@github.com/flox/builtfilter?ref=builtfilter-rs";
  inputs.builtfilter.inputs.capacitor.follows = "capacitor";
  # =================================

  nixConfig.bash-prompt = "[flox] \\[\\033[38;5;172m\\]λ \\[\\033[0m\\]";
  outputs = args @ {capacitor, ...}: capacitor args (import ./flox.nix);
}
