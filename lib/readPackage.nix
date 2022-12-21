# capacitor context
{
  self,
  lib,
  inputs,
}:
# First argument:
# Externally determined metadata
{
  attrPath ? [],
  namespace ? [],
  channel ? "unknown",
}:
# Second argument
# enable (implicit) building
{
  analyzeOutput ? substituteOnly,
  # if true uses builtins.storePath which does not attempts to build
  # requires `--impure`
  substituteOnly ? false,
  ...
} @ buildOptions: drv: let
  inherit (self.lib) inspectBuild;

  element = {
    active = true;
    attrPath = attrPath;
    originalUrl = null;
    url = null;
    storePaths = lib.attrValues eval.outputs;
  };

  eval = {
    # flake.locked = builtins.removeAttrs inputs.target.sourceInfo ["outPath"];
    inherit (drv) name system meta;
    inherit attrPath namespace;
    drvPath = builtins.unsafeDiscardStringContext drv.drvPath;
    pname = (builtins.parseDrvName drv.name).name;
    version =
      if (builtins.parseDrvName drv.name).version != ""
      then (builtins.parseDrvName drv.name).version
      else if drv ? version && drv.version != "" && drv.version != null
      then drv.version
      else "unknown";
    outputs = lib.genAttrs drv.outputs (output: builtins.unsafeDiscardStringContext drv.${output}.outPath);
  };
in {
  inherit element eval;
  build = lib.optionalAttrs analyzeOutput (inspectBuild buildOptions drv.outPath);
}
