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

  # reexport of capacitor, defaultPlugins, project, lib, templates, apps
  #passthru = { inherit (inputs.flox) capacitor defaultPlugins project lib templates apps; };
  passthru.project = inputs.flox.project;

  passthru."hydraJobsStaging" = hydraOverride ["nixpkgs" "nixpkgs"] ["nixpkgs" "nixpkgs-staging"];
  passthru."hydraJobsUnstable" = hydraOverride ["nixpkgs" "nixpkgs"] ["nixpkgs" "nixpkgs-unstable"];
  passthru."hydraJobsStable" = hydraOverride ["nixpkgs" "nixpkgs"] ["nixpkgs" "nixpkgs-stable"];
}
