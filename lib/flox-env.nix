# Capacitor API
{
  self,
  inputs,
  lib,
}:
let floxpkgs = self; in
# User API
pkgs': toml: pins: let
  tie = {
    pkgs = pkgs';
    mach = floxpkgs.inputs.mach-nix.lib.${pkgs.system};
    vscodeLib = lib.vscode;
  };
  data = {
    func = floxEnv;
    attrs = if builtins.isAttrs toml then toml else builtins.fromTOML (builtins.readFile toml);
  };
  pkgs = tie.pkgs;
    floxEnv = {programs, ...}: let
    python = let
      mach = import (floxpkgs.inputs.mach-nix + "/default.nix") {
        inherit pkgs;
        dataOutdated = false;
        pypiData = floxpkgs.inputs.mach-nix.inputs.pypi-deps-db;
      };
    in
      mach.mkPython (programs.python
        // {
          ignoreDataOutdated = true;
        });
    paths = let
      handler = {
        python = python;
        vscode =
          floxpkgs.lib.vscode.configuredVscode
          pkgs
          programs.vscode
          pins.vscode-extensions;

        # insert excpetions here
        __functor = self: key: attr:
          self.${key}
          or (
            if attr ? version
            then "${key}@${attr.version}"
            else pkgs.${key}
          );
      };
    in
      lib.mapAttrsToList handler programs;
  in
    (pkgs.buildEnv {
      name = "flox-env";
      inherit paths;
    })
    // {
      passthru = {
        inherit programs paths;
        python.expr = python.expr;
      };
    };
in
  data
