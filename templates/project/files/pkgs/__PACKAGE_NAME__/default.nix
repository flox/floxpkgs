{
  mkShell,
  stdenv,
  terraform,
  zlib,
}:
#
# Create a development shell using three sections:
# `packages`, `buildInputs`, and `shellHook`.
#
mkShell {
  #
  # Compilers and libraries go here
  #
  buildInputs = [
    stdenv.cc
    zlib
  ];
  #
  # Add extra tools here
  #
  packages = [
    terraform
  ];
  #
  # Additional shell hooks go here
  #
  shellHook = ''
    CHECKPOINT_DISABLE=1 terraform --version
  '';
}
