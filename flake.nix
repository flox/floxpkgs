{
  nixConfig.extra-substituters = ["https://cache.floxdev.com"];
  nixConfig.extra-trusted-public-keys = ["flox-store-public-0:8c/B+kjIaQ+BloCmNkRUKwaVPFWkriSAd0JJvuDu4F0="];

  # TODO: is this still needed?
  inputs.catalog.url = "github:flox/floxpkgs?ref=publish";
  inputs.catalog.flake = false;

  # Declaration of external resources
  # =================================

  # TODO: We name the following flake input `flox-floxpkgs` since we CLI
  #       overwrites flox-floxpkgs/nixpkgs/nixpkgs flake input.
  #       We should change that to `flox/nixpkgs-flox/nixpkgs`
  inputs.flox-floxpkgs.url = "git+ssh://git@github.com/flox/flox?ref=next";
  inputs.flox.follows = "flox-floxpkgs";

  inputs.tracelinks.url = "git+ssh://git@github.com/flox/tracelinks?ref=main";
  inputs.tracelinks.inputs.flox.follows = "flox-floxpkgs";

  inputs.builtfilter.url = "github:flox/builtfilter?ref=builtfilter-rs";
  inputs.builtfilter.inputs.flox.follows = "flox-floxpkgs";
  # =================================

  outputs = args @ {flox-floxpkgs, ...}: flox-floxpkgs.project args (_: {});
}
