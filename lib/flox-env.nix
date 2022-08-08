# Capacitor API
{
  self,
  inputs,
  lib,
}: let
  floxpkgs = self;
in
  # User API
  pkgs': toml: pins: let
    tie = {
      pkgs = pkgs';
      mach = floxpkgs.inputs.mach-nix.lib.${pkgs.system};
      vscodeLib = lib.vscode;
    };
    data = {
      func = floxEnv;
      attrs =
        if builtins.isAttrs toml
        then toml
        else builtins.fromTOML (builtins.readFile toml);
    };
    pkgs = tie.pkgs;
    floxEnv = {programs, ...}: let
      python = config: let
        mach = import (floxpkgs.inputs.mach-nix + "/default.nix") {
          inherit pkgs;
          dataOutdated = false;
          pypiData = floxpkgs.inputs.mach-nix.inputs.pypi-deps-db;
        };
      in
        mach.mkPython (config
          // {
            ignoreDataOutdated = true;
          });
      paths = let
        handler = {
          python = python;
          vscode = config:
            floxpkgs.lib.vscode.configuredVscode
            pkgs
            config
            pins.vscode-extensions;

          # insert exceptions here
          __functor = self: key: config:
            if builtins.hasAttr key self
            then self.${key} config
            else if config ? version
            then "${key}@${config.version}"
            else pkgs.${key};
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
