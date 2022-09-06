{ lib, beam, ...}:

let
  # beam.interpreters.erlangR23 is available if you need a particular version
  packages = beam.packagesWith beam.interpreters.erlang;

  pname = "my-package";
  version = "0.0.0";

  src = ../.;

  MIX_ENV="prod";
  # flox will create a "fixed output derivation" based on
  # the total package of fetched mix dependencies
  mixFodDeps = packages.fetchMixDeps {
    pname = "mix-deps-${pname}";
    inherit src version;
    # flox will complain and tell you the right sha256 value to replace this with
    sha256 = lib.fakeSha256;
    #sha256 = "";
  };

in packages.mixRelease {
  MIX_ENV="prod";
  inherit src pname version mixFodDeps;
  # for phoenix framework you can uncomment the lines below
  #postBuild = ''

    # for external task you need a workaround for the no deps check flag
    # https://github.com/phoenixframework/phoenix/issues/2690
    #mix do deps.loadpaths --no-deps-check, phx.digest
    #mix phx.digest --no-deps-check
   # mix do deps.loadpaths --no-deps-check
  #'';
}

