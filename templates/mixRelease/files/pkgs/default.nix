{
  self,
  lib,
  beam,
  mix2nix,
  ...
}: let
  # You can specify the OTP version by appending R + version number to the "erlang" attribute,
  # for example: beam.interpreters.erlangR23
  beamPackages = beam.packagesWith beam.interpreters.erlang;
  # Same here, you can specify the Elixir version by modifying "elixir" to "elixir_1_13", for example.
  elixir = beamPackages.elixir;
in
  beamPackages.mixRelease rec {
    pname = "my-package";
    version = "0.0.0";
    src = self; # + "/src";

    MIX_ENV = "prod";

    buildInputs = [ mix2nix elixir ];

    # At the root of your project directory, run "mix2nix > deps.nix" to create this file.
    mixNixDeps = import ./../deps.nix { inherit lib beamPackages; };

    # for phoenix framework you can uncomment the lines below
    # for external task you need a workaround for the no deps check flag
    # https://github.com/phoenixframework/phoenix/issues/2690

    #postBuild = ''
    #
    # mix do deps.loadpaths --no-deps-check, phx.digest
    # mix phx.digest --no-deps-check
    # mix do deps.loadpaths --no-deps-check
    #'';
  }
