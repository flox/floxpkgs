# capacitor context
{lib}: drv: let
  outputs = drv.outputs or ["out"];
in
  lib.genAttrs outputs (output: builtins.unsafeDiscardStringContext drv.${output}.outPath)
