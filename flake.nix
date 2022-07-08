rec {
  inputs.capacitor.url = "github:flox/capacitor/minicapacitor";
  inputs.capacitor.inputs.root.follows = "/";

  inputs.nixpkgs.url = "github:flox/nixpkgs-flox";

  # Declaration of external resources
  # =================================

  inputs.flox.url = "github:flox/flox/tng";
  inputs.nix-editor.url = "github:vlinkz/nix-editor";

  inputs.devshell.url = "github:numtide/devshell";
  inputs.mach-nix.url = "github:DavHau/mach-nix";
  inputs.mach-nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.mach-nix.inputs.pypi-deps-db.follows = "pypi-deps-db";
  inputs.pypi-deps-db.url = "github:DavHau/pypi-deps-db";
  inputs.pypi-deps-db.flake = false;
  
  # =================================

  nixConfig.bash-prompt = "[flox] \\[\\033[38;5;172m\\]λ \\[\\033[0m\\]";
  outputs = args @ {capacitor, ...}: capacitor args (import ./flox.nix);
}
