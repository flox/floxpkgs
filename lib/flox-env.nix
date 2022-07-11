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
    python = floxpkgs.inputs.mach-nix.lib.${pkgs.system}.mkPython programs.python;
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
    paths = lib.mapAttrsToList handler programs;
    elements = lib.mapAttrsToList (name: value: { attr = name; value = handler name value;}) programs;
  in
    (pkgs.buildEnv {
      name = "flox-env";
      inherit paths;
    })
    // {
      passthru = {
        inherit programs paths elements;
        python.expr = python.expr;
      };
    };
in
  data
