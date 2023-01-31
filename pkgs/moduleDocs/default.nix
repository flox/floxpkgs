{
  lib,
  system,
  context,
  inputs,
  self,
}: let
  moduleEval = lib.evalModules {
    modules = [
      {
        _module.args = {
          inherit context system;
          namespace = ["environment name"];
        };
      }
      "${self}/modules"
    ];
  };
in
  self.lib.nixosOptionsDoc {
    inherit system;
    options = builtins.removeAttrs moduleEval.options ["_module"];
  }
