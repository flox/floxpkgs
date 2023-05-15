{
  gnumake,
  mkShell,
  stdenv,
  zlib,
}:
#
# Create a development shell using three sections:
# `packages`, `buildInputs`, and `shellHook`.
#
mkShell {
  # Compilers and libraries go here
  buildInputs = [
    stdenv.cc
    zlib
  ];

  # Add extra tools here
  packages = [
    gnumake
  ];

  # Any variable set in this block that isn't a reserved word will be set as an
  # environment variable in the environment.
  WELCOME_MESSAGE = "Run make to build this project";

  # A shell hook is a script to run when entering an environment.
  # It can be used to perform any custom activation steps needed for your
  # project.
  shellHook = ''
    make --version
    echo
    echo "$WELCOME_MESSAGE"
  '';
}
