rec {
  nixConfig.extra-substituters = ["https://cache.floxdev.com?trusted=1"];

  inputs.capacitor.url = "github:flox/capacitor";
  inputs.capacitor.inputs.root.follows = "/";

  inputs.flox-extras.url = "github:flox/flox-extras";
  inputs.flox-extras.inputs.capacitor.follows = "capacitor";

  inputs.catalog.url = "github:flox/floxpkgs?ref=publish";
  inputs.catalog.flake = false;

  inputs.nixpkgs.url = "github:flox/nixpkgs-flox";
  inputs.nixpkgs.inputs.flox-extras.follows = "flox-extras";

  # Declaration of external resources
  # =================================

  inputs.flox.url = "git+ssh://git@github.com/flox/flox?ref=main";
  inputs.flox.flake = false;

  inputs.tracelinks.url = "git+ssh://git@github.com/flox/tracelinks?ref=main";
  inputs.tracelinks.flake = false;

  inputs.builtfilter.url = "github:flox/builtfilter?ref=builtfilter-rs";
  inputs.builtfilter.inputs.capacitor.follows = "capacitor";
  # =================================

  nixConfig.bash-prompt = "[flox] \\[\\033[38;5;172m\\]λ \\[\\033[0m\\]";
  outputs = args @ {capacitor, ...}: capacitor args (import ./flox.nix);
}
