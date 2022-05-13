rec {
  inputs.lib.url = "github:nix-community/nixpkgs.lib";

  inputs.nixpkgs-stable.url = "github:flox/nixpkgs/stable";
  inputs.nixpkgs-unstable.url = "github:flox/nixpkgs/unstable";
  inputs.nixpkgs-staging.url = "github:flox/nixpkgs/staging";

  inputs.capacitor.url = "git+ssh://git@github.com/flox/capacitor?ref=ysndr";
  inputs.capacitor.inputs.nixpkgs.follows = "nixpkgs-unstable";
  inputs.capacitor.inputs.root.follows = "/";

  inputs.cached__nixpkgs-stable__x86_64-linux.url = "https://hydra.floxsdlc.com/channels/nixpkgs/stable/x86_64-linux.tar.gz";

  inputs.tracelinks.url = "git+ssh://git@github.com/flox/tracelinks?ref=main";
  inputs.tracelinks.flake = false;

  outputs = {self, capacitor, ...} @ args: (capacitor args ({auto,...}: rec {
    legacyPackages = {system,...}: rec {
      # TODO: fold into capacitor
      tracelinks = args.tracelinks;
      nixpkgs = args.lib.lib.recurseIntoAttrs (builtins.mapAttrs (_: x: args.lib.lib.recurseIntoAttrs x) {
        stable   = args.nixpkgs-stable.legacyPackages.${system};
        unstable = args.nixpkgs-unstable.legacyPackages.${system};
        staging  = args.nixpkgs-staging.legacyPackages.${system};
      });

      flox = args.lib.lib.recurseIntoAttrs (builtins.mapAttrs (_: x: args.lib.lib.recurseIntoAttrs x) {
        unstable = auto.automaticPkgsWith inputs ./pkgs nixpkgs.unstable;
        stable = auto.automaticPkgsWith inputs ./pkgs nixpkgs.stable;
        staging = auto.automaticPkgsWith inputs ./pkgs nixpkgs.staging;
      });

      cached.nixpkgs.stable = if system == "x86_64-linux"
                              then args.cached__nixpkgs-stable__x86_64-linux.legacyPackages.${system}
                              else {};

      search.nixpkgs.recurseForDerivations = true;
      search.nixpkgs.stable = args.lib.lib.recurseIntoAttrs (capacitor.lib.mapAttrsRecursiveCond
        (path: a: (a?element))
        (path: value: {
          type="derivation";
          name = builtins.concatStringsSep "." (args.lib.lib.init path);
          meta.description = "";
          version = "";
        })
            self.legacyPackages.x86_64-linux.nixpkgs.stable);
    };

    # apps = auto.automaticPkgsWith inputs ./apps ;
  }));
}
