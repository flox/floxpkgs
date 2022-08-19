# Capacitor API (using callPackage > requires self to be named explicitly)
capacitorContext @ {self}: toml: pins: context @ {pkgs, ...}: let
  data =
    capacitorContext.self.lib.flox-env
    pkgs
    toml
    pins;
in
  capacitorContext.self.lib.mkNakedShell {
    inherit (capacitorContext.inputs.devshell.packages) devshell;
    inherit data;
    inherit pkgs;
    inherit pins;
    floxpkgs = capacitorContext.self;
    lib = capacitorContext.self.lib;
  }
