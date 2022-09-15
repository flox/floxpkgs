{
  stdenv,
  bundlerEnv,
  ruby,
}: let
  # running the bundix command
  # will generate the gemset.nix file below
  gems = bundlerEnv {
    name = "my-package-env";
    inherit ruby;
    gemfile = ../Gemfile;
    lockfile = ../Gemfile.lock;
    gemset = ../gemset.nix;
  };
in
  stdenv.mkDerivation rec {
    name = "my-package";
    src = ../.;
    buildInputs = [gems ruby];
    installPhase = ''
      mkdir -p $out/bin  $out/share/${name}
      cp -r * $out/share/${name}
      bin=$out/bin/${name}
      # we are using bundle exec to start in the bundled environment
      cat > $bin <<EOF
      #!/bin/sh -e
        exec ${gems}/bin/bundle exec ${ruby}/bin/ruby $out/share/${name}/lib/${name}.rb "\$@"
      EOF
      chmod +x $bin
    '';
  }
