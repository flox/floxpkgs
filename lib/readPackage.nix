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
  flakeRef ? null, # "self" gets special treatment
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
  flake = ( import ./lockFlake.nix { inherit inputs; } ) flakeRef;

  eval = {
    inherit (drv) name system;
    inherit attrPath namespace;
    drvPath = builtins.unsafeDiscardStringContext drv.drvPath;
    pname   = (builtins.parseDrvName drv.name).name;
    version =
      if (builtins.parseDrvName drv.name).version != ""
      then (builtins.parseDrvName drv.name).version
      else if drv ? version && drv.version != "" && drv.version != null
      then drv.version
      else "unknown";
    # Collect `outPath' for each output, stripping context so we can emit them
    # as strings later.
    outputs = let
      outputs = drv.outputs or ["out"];
      proc    = o:
        builtins.unsafeDiscardStringContext ( builtins.getAttr o drv ).outPath;
    in lib.genAttrs outputs proc;
    meta = drv.meta or {};
  };

  element = {
    active = true;
    inherit attrPath;
    originalUrl = if flakeRef == null   then null else
                  if flakeRef == "self" then "."  else
                  flake.originalRef.string;
    url = if flakeRef == null   then null else
          if flakeRef == "self" then ""   else
          flake.lockedRef.string;
    # TODO this violates the catalog schema, so it must be set with
    # postprocessing
    storePaths =
      if drv ? meta.outputsToInstall
      then
        # only include outputsToInstall
        (builtins.map (outputName: eval.outputs.${outputName})
          drv.meta.outputsToInstall)
      else lib.attrValues eval.outputs;
  };
in {
  inherit element eval;
  build = lib.optional analyzeOutput (inspectBuild buildOptions drv.outPath);
  version = 1;
}
