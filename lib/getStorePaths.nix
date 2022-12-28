{self}: drv: let
  outputs = self.lib.getOutputs drv;
in
  if drv.meta ? outputsToInstall
  then
    # only include outputsToInstall
    (builtins.map (outputName: outputs.${outputName})
      drv.meta.outputsToInstall)
  else builtins.attrValues outputs
