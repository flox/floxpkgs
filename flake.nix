rec {
  inputs.capacitor.url = "git+ssh://git@github.com/flox/capacitor?ref=ysndr";
  inputs.capacitor.inputs.root.follows = "/";

  inputs.cached__nixpkgs-stable__x86_64-linux.url = "https://hydra.floxsdlc.com/channels/nixpkgs/stable/x86_64-linux.tar.gz";

  inputs.tracelinks.url = "git+ssh://git@github.com/flox/tracelinks?ref=main";
  inputs.tracelinks.flake = false;

  outputs = {
    self,
    capacitor,
    ...
  } @ args:
    capacitor args ({auto, ...}: rec {

      packages = {system, pkgs', ...}: auto.automaticPkgsWith inputs ./pkgs pkgs';

      legacyPackages = {system, pkgs', ...}: {

        nixpkgs = capacitor.lib.recurseIntoAttrs2 pkgs';

        flox = capacitor.lib.recurseIntoAttrs2 {
          unstable = auto.automaticPkgsWith inputs ./pkgs pkgs'.unstable;
          stable = auto.automaticPkgsWith inputs ./pkgs pkgs'.stable;
          staging = auto.automaticPkgsWith inputs ./pkgs pkgs'.staging;
        };

        # package set with eval+built invariant
        cached.nixpkgs.stable =
          if system == "x86_64-linux"
          then args.cached__nixpkgs-stable__x86_64-linux.legacyPackages.${system}
          else {};

        # Provides a search speedup, bypassing descriptions
        search = {
          recurseForDerivations = true;
          nixpkgs = capacitor.lib.recurseIntoAttrs2 (
            capacitor.lib.mapAttrsRecursiveCond
            (path: a: (a ? element))
            (path: value: {
              type = "derivation";
              name = builtins.concatStringsSep "." (capacitor.lib.init path);
              meta.description = "";
              version = "";
            })
            self.legacyPackages.x86_64-linux.nixpkgs);
        };
      };

      # apps = auto.automaticPkgsWith inputs ./apps ;
    });
}
