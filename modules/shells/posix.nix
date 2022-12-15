# options and implementation for all POSIX shells
{
  config,
  lib,
  pkgs,
  self,
  context,
  attrPath,
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

  config = {
    toplevel = self.lib.mkEnv {
      inherit pkgs context attrPath;
      env = config.variables or {};
      aliases = config.shell.aliases or {};
      postShellHook = config.shell.hook or "";
      packages = config.environment.systemPackages ++ [config.newCatalogPath];
      manifestPath = config.manifestPath;
    };
  };
}
