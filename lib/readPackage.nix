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
  flakeRef ? null,  # Normally a type
  useFloxEnvChanges ? false,
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

  element = rec {
    active = true;
    inherit attrPath;
    # normalize to include "flake:", which is included in manifest.json
    originalUrl =
      if flakeRef?outPath
      then "." # TODO: use outPath?
      else
      (if flakeRef == null || builtins.match ".*:.*" flakeRef == []
      then flakeRef
      else "flake:${flakeRef}");
    url =
      # TODO; clean up this abuse of the type system
      if flakeRef?outPath
      then ""
      else
      if useFloxEnvChanges
      then let
        flake =
          builtins.getFlake flakeRef;
        # this assumes that either flakeRef is not indirect, or if it is indirect, the flake it
        # resolves to contains a branch
      in "${originalUrl}/${flake.rev}"
      else null;
    storePaths =
      if useFloxEnvChanges
      then self.lib.getStorePaths drv
      else lib.attrValues eval.outputs;
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
    outputs = self.lib.getOutputs drv;
  };
in {
  inherit element eval;
  build = lib.optionalAttrs analyzeOutput (inspectBuild buildOptions drv.outPath);
}
