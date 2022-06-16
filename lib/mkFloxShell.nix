_: toml: pins: {pkgs, ...}: let
  data =
    _.self.lib.flox-env {
      inherit (_) mach-nix;
      lib = _.self.lib;
    }
    pkgs
    toml
    pins;
in
  _.self.lib.mkNakedShell {
    inherit (_) devshell;
    inherit data;
    inherit pkgs;
    inherit pins;
    floxpkgs = _.self;
    lib = _.self.lib;
  }
