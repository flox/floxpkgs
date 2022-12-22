{
  nixConfig.extra-substituters = ["https://cache.floxdev.com"];
  nixConfig.extra-trusted-public-keys = ["flox-store-public-0:8c/B+kjIaQ+BloCmNkRUKwaVPFWkriSAd0JJvuDu4F0="];

  inputs.capacitor.url = "github:flox/capacitor";

  inputs.catalog.url = "github:flox/floxpkgs?ref=publish";
  inputs.catalog.flake = false;

  inputs.nixpkgs.url = "github:flox/nixpkgs-flox";
  inputs.nixpkgs.inputs.floxpkgs.follows = "";

  # Declaration of external resources
  # =================================

  inputs.flox.url = "git+ssh://git@github.com/flox/flox-bash?ref=main";
  inputs.flox.inputs.floxpkgs.follows = "/";

  inputs.tracelinks.url = "git+ssh://git@github.com/flox/tracelinks?ref=fix/overlay-trees";
  inputs.tracelinks.inputs.floxpkgs.follows = "/";

  inputs.builtfilter.url = "github:flox/builtfilter?ref=builtfilter-rs";
  inputs.builtfilter.inputs.capacitor.follows = "capacitor";
  # =================================

  nixConfig.bash-prompt = "[flox] \\[\\033[38;5;172m\\]λ \\[\\033[0m\\]";
  outputs = args @ {capacitor, ...}: capacitor args (import ./flox.nix);
}
