rec {
  inputs.lib.url = "github:nix-community/nixpkgs.lib";

  inputs.nixpkgs-stable.url = "git+ssh://git@github.com/flox/nixpkgs-flox";
  inputs.nixpkgs-stable-src.url = "github:flox/nixpkgs/stable";
  inputs.nixpkgs-stable.inputs.nixpkgs.follows = "nixpkgs-stable-src";

  inputs.nixpkgs-unstable.url = "git+ssh://git@github.com/flox/nixpkgs-flox";
  inputs.nixpkgs-unstable-src.url = "github:flox/nixpkgs/unstable";
  inputs.nixpkgs-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable-src";

  inputs.nixpkgs-staging.url = "git+ssh://git@github.com/flox/nixpkgs-flox";
  inputs.nixpkgs-staging-src.url = "github:flox/nixpkgs/staging";
  inputs.nixpkgs-staging.inputs.nixpkgs.follows = "nixpkgs-staging-src";

  inputs.capacitor.url = "git+ssh://git@github.com/flox/capacitor?ref=ysndr";
  inputs.capacitor.inputs.nixpkgs.follows = "nixpkgs-unstable";
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

      packages = {system, ...}: auto.automaticPkgsWith inputs ./pkgs args.nixpkgs-stable.legacyPackages.${system};

      legacyPackages = {system, ...}: rec {

        nixpkgs = capacitor.lib.recurseIntoAttrs2 {
          stable = args.nixpkgs-stable.legacyPackages.${system};
          unstable = args.nixpkgs-unstable.legacyPackages.${system};
          staging = args.nixpkgs-staging.legacyPackages.${system};
        };

        flox = capacitor.lib.recurseIntoAttrs2 {
          unstable = auto.automaticPkgsWith inputs ./pkgs nixpkgs.unstable;
          stable = auto.automaticPkgsWith inputs ./pkgs nixpkgs.stable;
          staging = auto.automaticPkgsWith inputs ./pkgs nixpkgs.staging;
        };

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
              name = builtins.concatStringsSep "." (args.lib.lib.init path);
              meta.description = "";
              version = "";
            })
            self.legacyPackages.x86_64-linux.nixpkgs);
        };
      };

      # apps = auto.automaticPkgsWith inputs ./apps ;
    });
}
