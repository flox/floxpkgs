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
            # Allow user to optionally specify stability, channel, and version
            getCatalogAttrFromPath = with builtins;
              path: catalog: let
                # default to stable is user doesn't specify stability
                withStability =
                  if catalog ? ${head path}
                  then withChannel (tail path) catalog.${head path}
                  else withChannel path catalog.stable;
                # default to nixpkgs if user doesn't specify channel
                withChannel = path: stability:
                  if stability ? ${head path}
                  then withVersion (tail path) stability.${head path}
                  else withVersion path stability.nixpkgs;
                # translate version into an attrPath if it's provided. Otherwise, fallback to the
                # way the evalCatalog provides latest
                withVersion = path: channel: let
                  rightmostAttr = elemAt path (length path - 1);
                  splitRightmostAttr = lib.splitString "@" rightmostAttr;
                in
                  # we have an @version
                  if length splitRightmostAttr == 2
                  then let
                    # because of nested attributes, we have to sure we preserve any part of the
                    # attrPath between channel and the rightmost attribute
                    allAttrsButRightmost =
                      if length path > 1
                      then lib.sublist 0 (length path - 2) path
                      else [];
                    versionWithUnderscores = replaceStrings ["."] ["_"] (elemAt splitRightmostAttr 1);
                  in
                    lib.getAttrFromPath (allAttrsButRightmost ++ [(head splitRightmostAttr) versionWithUnderscores]) channel
                  # no version
                  else if length splitRightmostAttr == 1
                  then lib.getAttrFromPath path channel
                  else throw "can't handle multiple '@' characters in ${rightmostAttr}";
              in
                withStability;
          in
            # return a list of fake derivations retrieved from the catalog
            builtins.map (path: getCatalogAttrFromPath path floxpkgs.evalCatalog.${pkgs.system}) (pathsToLeaves programs);

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
