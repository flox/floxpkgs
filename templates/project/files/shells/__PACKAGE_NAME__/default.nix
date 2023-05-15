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
    gnumake
  ];
  #
  # Additional shell hooks go here
  #
  shellHook = ''
    make --version
  '';
}
