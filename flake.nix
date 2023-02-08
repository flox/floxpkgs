{
  nixConfig.extra-substituters = ["https://cache.floxdev.com"];
  nixConfig.extra-trusted-public-keys = ["flox-store-public-0:8c/B+kjIaQ+BloCmNkRUKwaVPFWkriSAd0JJvuDu4F0="];

  inputs.capacitor.url = "github:flox/capacitor?ref=v0";

  inputs.catalog.url = "github:flox/floxpkgs?ref=publish";
  inputs.catalog.flake = false;

  inputs.nixpkgs.url = "github:flox/nixpkgs-flox";
  inputs.nixpkgs.inputs.flox-floxpkgs.follows = "/";
  inputs.nixpkgs.inputs.flox-bash.follows = "flox-bash";
  inputs.nixpkgs.inputs.flox.follows = "flox";

  # Declaration of external resources
  # =================================

  inputs.flox.url = "git+ssh://git@github.com/flox/flox?ref=main";
  inputs.flox.inputs.flox-floxpkgs.follows = "/";
  inputs.flox.inputs.flox-bash.follows = "flox-bash";
  inputs.flox-bash.url = "git+ssh://git@github.com/flox/flox-bash?ref=main";
  inputs.flox-bash.inputs.flox-floxpkgs.follows = "/";

  inputs.builtfilter.url = "github:flox/builtfilter?ref=builtfilter-rs";
  inputs.builtfilter.inputs.capacitor.follows = "capacitor";
  # =================================

  nixConfig.bash-prompt = "[flox] \\[\\033[38;5;172m\\]λ \\[\\033[0m\\]";
  outputs = args @ {capacitor, ...}: capacitor args (import ./flox.nix);
}
