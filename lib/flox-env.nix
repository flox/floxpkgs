# Capacitor API
{
  self,
  inputs,
  lib,
  args,
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
        handler = let
          pathsToLeaves = programs:
            lib.collect builtins.isList (lib.mapAttrsRecursiveCond (attr: attr != {}) (path: _: path) programs);
        in {
          python = python;
          vscode = config:
            floxpkgs.lib.vscode.configuredVscode
            pkgs
            config
            pins.vscode-extensions;

          catalog = programs: let
            defaultVersion = with builtins;
              path: let
                # TODO shouldn't include recurseForDerivations
                versionsWithUnderScores = attrNames (lib.getAttrFromPath
                  path
                  nixpkgs-flox.catalog.${pkgs.system});
                versions = map (version: replaceStrings ["_"] ["."] version) versionsWithUnderScores;
                sortedVersions = sort (v1: v2: (compareVersions v1 v2) == 1) versions;
              in
                replaceStrings ["."] ["_"] (head sortedVersions);
            ensureStabilityAndVersion = with builtins;
              path:
                if length path == 2
                then path ++ [(defaultVersion path)]
                else if length path == 1
                then ensureStabilityAndVersion (path ++ ["stable"])
                else path;
          in
            # return a list of fake derivations retrieved from the catalog
            # TODO use inputs once system is correctly detected
            builtins.map (path: lib.getAttrFromPath (ensureStabilityAndVersion path) args.nixpkgs.catalog.${pkgs.system}) (pathsToLeaves programs);

          floxpkgs = programs:
            builtins.map (path: lib.getAttrFromPath path self.catalog.${pkgs.system}.floxpkgs) (pathsToLeaves programs);

          # insert exceptions here
          __functor = self: key: config:
            if builtins.hasAttr key self
            then self.${key} config
            else if config ? version
            then "${key}@${config.version}"
            else pkgs.${key};
        };
      in
        lib.flatten (lib.mapAttrsToList handler programs);
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
