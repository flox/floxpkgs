# options that all runners (e.g. bash, eventually containers) should use
{
  config,
  lib,
  ...
}:
with lib; {
  options = {
    variables = mkOption {
      default = {};
      example = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
      description = lib.mdDoc ''
        A set of environment variables. The value of each variable can be either a string or a list of
        strings.  The latter is concatenated, interspersed with colon
        characters.
      '';
      type = with types; attrsOf (either str (listOf str));
      apply = mapAttrs (n: v:
        if isList v
        then concatStringsSep ":" v
        else v);
    };

    toplevel = mkOption {
      type = types.package;
    };
  };
}
