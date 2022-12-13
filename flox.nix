{
  self,
  inputs,
  lib,
  ...
}:
  # re-call yourself with overrides, will not work if using in-memory lockfile
  let hydraOverride = path: follows: (inputs.capacitor.lib.capacitor.callFlake
    (builtins.readFile (self + "/flake.lock"))
    self "" "" "root" { }
    [ {
        path = path;
        follows = follows;
      } ]
    ).hydraJobs;
  in
# Define package set structure
{
  # Limit the systems to fewer or more than default by ucommenting
  packages = {
    builtfilter = {capacitated, ...}: capacitated.builtfilter.packages.builtfilter-rs;
  };

  config = {
    extraPlugins = [
      (inputs.capacitor.plugins.allLocalResources {})
      (import ./plugins/catalog.nix { inherit self lib; } {})
      (inputs.capacitor.plugins.plugins { dir = ./plugins; })

      (inputs.capacitor.plugins.templates {})
    ];
  };

  # reexport of capacitor
  passthru.capacitor = inputs.capacitor;
  # define default plugins
  passthru.defaultPlugins = [
    (inputs.capacitor.plugins.allLocalResources {})
    (import ./plugins/catalog.nix {inherit self lib;} {})
    (import ./plugins/floxEnvs.nix {inherit self lib;} {
      sourceType="packages";
      dir="pkgs";
    })
  ];

  passthru.project = args: config:
    inputs.capacitor args (
      context:
        lib.recursiveUpdate {
          config.plugins = inputs.capacitor.defaultPlugins ++ self.defaultPlugins;
        }
        (config context)
    );

  passthru."hydraJobsStaging" = hydraOverride ["nixpkgs" "nixpkgs"] ["nixpkgs" "nixpkgs-staging"];
  passthru."hydraJobsUnstable" = hydraOverride ["nixpkgs" "nixpkgs"] ["nixpkgs" "nixpkgs-unstable"];
  passthru."hydraJobsStable" = hydraOverride ["nixpkgs" "nixpkgs"] ["nixpkgs" "nixpkgs-stable"];
}
