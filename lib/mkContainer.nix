# at this point just a thin wrapper around streamLayeredImage, but still worth
# having to keep as much functionality as possible in lib rather than the module
# system
{
  inputs,
  lib,
}: {
  context,
  system,
  drv,
  entrypoint ? null,
  buildLayeredImageArgs,
}: let
  pkgs = context.nixpkgs.legacyPackages.${system};
  name = buildLayeredImageArgs.name;
  builderArgsHaveEntrypoint = buildLayeredImageArgs ? config.entrypoint && buildLayeredImageArgs.config.entrypoint != null;
  runFloxActivate = entrypoint == null && !builderArgsHaveEntrypoint;
in
  pkgs.dockerTools.streamLayeredImage (lib.recursiveUpdate buildLayeredImageArgs
    {
      config = {
        entrypoint =
          if
            entrypoint
            != null
          then
            if builderArgsHaveEntrypoint
            then throw "cannot specify both entrypoint and config.entrypoint"
            else entrypoint
          else if runFloxActivate
          then ["${pkgs.bashInteractive}/bin/bash" "--rcfile" "${drv}/activate"]
          else buildLayeredImageArgs.config.entrypoint;
      };
      contents = [drv] ++ lib.optionals runFloxActivate (with pkgs; [bashInteractive coreutils]);
    })
