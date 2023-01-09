{
  context,
  system,
  config,
  lib,
  ...
}: let
  floxpkgs = context.inputs.flox-floxpkgs;
in {
  options.container = with lib; {
    name = mkOption {
      description = mdDoc ''The name of the resulting image.'';
      type = types.str;
      default = "floxEnv";
    };

    tag = mkOption {
      description = lib.mdDoc ''Tag of the generated image.'';
      type = types.str;
      default = "latest";
    };

    # fromImage = mkOption {
    #   description = lib.mdDoc ''The repository tarball containing the base image. It must be a valid Docker image, such as one exported by `docker save`.'';
    #   default = null;
    # };

    # contents = mkOption {
    #   description = lib.mdDoc ''Top-level paths in the container. Either a single derivation, or a list of derivations.'';
    #   default = [];
    # };

    # architecture = mkOption {
    #   description =
    #     lib.mdDoc ''
    #       used to specify the image architecture, this is useful for multi-architecture builds that don't need cross compiling. If not specified it will default to `hostPlatform`.'';
    #   default = {};
    # };

    config = mkOption {
      description = lib.mdDoc ''
        Run-time configuration of the container. A full list of the options
        are available at in the
        [Docker Image Specification v1.2.0](https://github.com/moby/moby/blob/master/image/spec/v1.2.md#image-json-field-descriptions).
        Note that config.env is not supported (use environmentVariables instead)
      '';
      type = types.anything;
      default = {};
    };

    created = mkOption {
      description = lib.mdDoc ''Date and time the layers were created.'';
      type = types.str;
      default = "now";
    };

    maxLayers = mkOption {
      description = lib.mdDoc ''Maximum number of layers to create. At most 125'';
      type = types.int;
      default = 100;
    };

    extraCommands = mkOption {
      description = lib.mdDoc ''
        Shell commands to run while building the final layer, without access to
        most of the layer contents. Changes to this layer are "on top" of all
        the other layers, so can create additional directories and files.
      '';
      type = types.lines;
      default = "";
    };

    # fakeRootCommands = mkOption {
    #   description = lib.mdDoc ''
    #     Shell commands to run while creating the archive for the final layer in
    #     a fakeroot environment. Unlike `extraCommands`, you can run `chown` to
    #     change the owners of the files in the archive, changing fakeroot's state
    #     instead of the real filesystem. The latter would require privileges that
    #     the build user does not have. Static binaries do not interact with the
    #     fakeroot environment. By default all files in the archive will be owned
    #     by root.
    #   '';
    #   default = null;
    # };

    # enableFakechroot = mkOption {
    #   description = lib.mdDoc ''
    #     Whether to run in `fakeRootCommands` in `fakechroot`, making programs
    #     behave as though `/` is the root of the image being created, while files
    #     in the Nix store are available as usual. This allows scripts that
    #     perform installation in `/` to work as expected. Considering that
    #     `fakechroot` is implemented via the same mechanism as `fakeroot`, the
    #     same caveats apply.
    #   '';
    #   default = false;
    # };

    entrypoint = mkOption {
      description = lib.mdDoc ''
        A command and its arguments to run when starting a container.
      '';
      type = types.nullOr (types.listOf types.str);
      default = null;
    };
  };
  config = {
    passthru.streamLayeredImage = let
      environmentVariables =
        if builtins.isList config.environmentVariables && config.container.entrypoint != null
        then throw "ordered environment variables are not supported in containers when entrypoint is specified"
        else (lib.mapAttrsToList (n: v: ''${n}=${v}'') config.environmentVariables);
    in
      floxpkgs.lib.mkContainer {
        inherit context system;
        drv = config.passthru.posix;
        buildLayeredImageArgs =
          lib.recursiveUpdate
          (builtins.removeAttrs config.container ["entrypoint"])
          {
            config.env =
              if (config.container.entrypoint != null)
              then environmentVariables
              # The default entrypoint (flox activation) will pull in
              # environmentVariables, and discard config.env for consistency
              # even if there is a different entrypoint
              else [];
          };
        entrypoint = config.container.entrypoint;
      };
  };
}
