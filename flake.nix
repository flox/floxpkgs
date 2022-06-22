rec {
  inputs.capacitor.url = "git+ssh://git@github.com/flox/capacitor";
  inputs.capacitor.inputs.root.follows = "/";

  inputs.nixpkgs.url = "git+ssh://git@github.com/flox/nixpkgs-flox";
  inputs.nixpkgs.inputs.capacitor.follows = "capacitor";
  inputs.capacitor.inputs.nixpkgs.follows = "nixpkgs";

  inputs.default.url = "path:./templates/default";
  inputs.default.inputs.capacitor.follows = "capacitor";
  inputs.default.inputs.floxpkgs.follows = "/";
  inputs.default.inputs.nixpkgs.follows = "nixpkgs";

  # Used for ops-env library functions. TODO: move to capacitor?
  inputs.devshell.url = "github:numtide/devshell";
  inputs.mach-nix.url = "github:DavHau/mach-nix";
  inputs.mach-nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.mach-nix.inputs.pypi-deps-db.follows = "pypi-deps-db";
  inputs.pypi-deps-db.url = "github:DavHau/pypi-deps-db";
  inputs.pypi-deps-db.flake = false;
  inputs.flox.url = "path:./pkgs/flox";
  nixConfig.bash-prompt = "[flox] \\[\\033[38;5;172m\\]λ \\[\\033[0m\\]";

  outputs = _: (_.capacitor _ ({
      self,
      lib,
      auto,
      ...
    }:
    # Define package set structure
    rec {
      # Limit the systems to fewer or more than default by ucommenting

      #packages = args: (legacyPackages args).flox;

      legacyPackages = {
        pkgs,
        system,
        stability ? "stable",
        ...
      }: rec {
        # Declare my channels (projects)
        nixpkgs = catalog.nixpkgs.${stability};
        flox = catalog.flox.${stability};
        catalog = _.capacitor.lib.recurseIntoAttrs2 rec {
          nixpkgs = lib.genAttrs ["stable" "unstable" "staging"] (
            stability:
              pkgs.${stability}
          );
          flox = lib.genAttrs ["stable" "unstable" "staging"] (stability:
            # support default.nix approach
              (auto.automaticPkgsWith inputs ./pkgs (lib.recursiveUpdate nixpkgs.${stability} flox.${stability}))
              # support flakes approach with override
              # searches in "inputs" for a url with "path:./" and call the flake with the root's lock
              // (lib.sanitizes (auto.callSubflakesWith inputs "path:./pkgs" {}) ["pins" "default" "packages" system])
              # External proto-derivaiton trees and overrides
              // (
                auto.usingWith inputs (import ./flox.nix {_ = _;}) (lib.recursiveUpdate nixpkgs.${stability} flox.${stability})
                # end customizations
              ));
        };
      };

      apps = {system,...}: let
        pkgsMerged = lib.recursiveUpdate
        self.legacyPackages.${system}.nixpkgs
        self.legacyPackages.${system}.flox
        ;
          in
          auto.automaticPkgsWith inputs ./apps pkgsMerged;

      # Create output jobsets for stabilities
      # TODO: has.stabilities and re-arrange attribute names to make system last?
      hydraJobsRaw = lib.genAttrs ["stable" "unstable" "staging"] (stability:
        let a = (lib.genAttrs ["x86_64-linux"] (
          system: let
            args = {
              inherit lib system;
              root' = _.capacitor.lib.sanitize _.capacitor.inputs.root system;
              pkgs = _.nixpkgs.legacyPackages.${system};
              inherit stability;
            };
            jobs = (legacyPackages args).flox;
            pkgs = (legacyPackages args).nixpkgs;
          in
            jobs
            // {
              gate =
                pkgs.runCommand "all-jobs" rec {
                  _hydraAggregate = true;
                  constituentList = lib.collect lib.isList (
                    lib.mapAttrsRecursiveCond
                    (value: !(lib.isDerivation value))
                    (path: value: path)
                    jobs
                  );
                  constituents = with builtins;
                    map (x: concatStringsSep "." ([system] ++ x)) constituentList;
                } ''
                  touch $out
                '';
            }
        )); in a // lib.over a);
      hydraJobsStable = self.hydraJobsRaw.stable;
      hydraJobsUnstable = self.hydraJobsRaw.unstable;
      hydraJobsStaging = self.hydraJobsRaw.staging;



      devShells = {system,...}:
        (lib.sanitizes (auto.callSubflakesWith inputs "path:./templates" {}) ["devShells" "packages" "legacyPackages" "apps" system]).default;

      lib =
        _.capacitor.lib
        // {
          flox-env = import ./lib/flox-env.nix;
          vscode = import ./lib/vscode.nix;
          mkNakedShell = import ./lib/mkNakedShell.nix;
          mkFloxShell = import ./lib/mkFloxShell.nix _;
          mkUpdateVersions = import ./lib/update-versions.nix _;
          mkUpdateExtensions = import ./lib/update-extensions.nix _;
        };

      templates = builtins.mapAttrs (k: v: {
        path = v.path;
        description = (import "${v.path}/flake.nix").description or "no description provided in ${v.path}/flake.nix";
      }) ( _.capacitor.lib.dirToAttrs ./templates {});
    }));
}
