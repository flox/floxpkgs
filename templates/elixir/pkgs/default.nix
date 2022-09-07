{
  lib,
  beam,
  ...
}: let
  # beam.interpreters.erlangR23 is available if you need a particular version
  packages = beam.packagesWith beam.interpreters.erlang;
in
  packages.mixRelease rec {
    MIX_ENV = "prod";

    pname = "my-package";
    version = "0.0.0";

    src = ../.;

    # flox will create a "fixed output derivation" based on
    # the total package of fetched mix dependencies
    mixFodDeps = packages.fetchMixDeps {
      inherit version src;
      pname = "mix-deps-${pname}";
      # nix will complain and tell you the right value to replace this with
      sha256 = lib.fakeSha256;
      #sha256 = "real sha256 here";
      # if you have build time environment variables add them here
      #MY_VAR="value";
    };

    #postBuild = ''

    # for phoenix framework you can uncomment the lines below
    # for external task you need a workaround for the no deps check flag
    # https://github.com/phoenixframework/phoenix/issues/2690
    #mix do deps.loadpaths --no-deps-check, phx.digest
    #mix phx.digest --no-deps-check
    # mix do deps.loadpaths --no-deps-check
    #'';
  }
