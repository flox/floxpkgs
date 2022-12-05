# options and implementation for all POSIX shells
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  # common options for POSIX compatible shells
  options = {
    shell = {
      aliases = mkOption {
        default = {};
        example = {
          ll = "ls -l";
        };
        description = lib.mdDoc ''
          An attribute set that maps aliases (the top level attribute names in
          this option) to command strings or directly to packages.
          Aliases mapped to `null` are ignored.
        '';
        type = with types; attrsOf (nullOr (either str path));
      };
      hook = mkOption {
        default = "";
        description = lib.mdDoc ''
          Shell script code called during environment activation.
          This code is assumed to be shell-independent, which means you should
          stick to pure sh without sh word split.
        '';
        type = types.lines;
      };
    };
  };

  config = let
    stringAliases = concatStringsSep "\n" (
      mapAttrsFlatten (k: v: "alias ${k}=${escapeShellArg v}")
      (filterAttrs (k: v: v != null) config.shell.aliases)
    );

    exportedEnvVars = let
      # make foo = "bar" -> foo = ["bar"]
      allValuesLists =
        mapAttrs (n: toList) config.variables;
      exportVariables =
        mapAttrsToList (n: v: ''export ${n}=${escapeShellArg (concatStringsSep ":" v)}'') allValuesLists;
    in
      concatStringsSep "\n" exportVariables;
    activateScript = pkgs.writeTextFile {
      name = "activate";
      executable = true;
      destination = "/activate";
      text = ''
        ${exportedEnvVars}

        ${stringAliases}

        ${config.shell.hook}
      '';
    };
  in {
    toplevel = pkgs.callPackage ../../lib/mkEnv.nix {} {
      packages = config.environment.systemPackages ++ [config.newCatalogPath activateScript];
    };
  };
}
