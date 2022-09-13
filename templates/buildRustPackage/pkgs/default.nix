{
  rustPlatform,
  # you can add imports here
}:
rustPlatform.buildRustPackage rec {
  pname = "my-package";
  version = "0.0.0";
  src = ../.;
  cargoLock = {
    lockFile = ../Cargo.lock;
    # The hash of each dependency that uses a git source must be specified.
    # The hash can be found by setting it to lib.fakeSha256 as shown below and running flox build.
    # The build will fail but output the expected sha, which can then be added here
    outputHashes = {
      #   "dependency-0.0.0" = lib.fakeSha256;
    };
  };
  # Non-Rust dependencies of your project can be added in buildInputs. Make sure to import any
  # additional dependencies above
  buildInputs =
    [openssl]
    # Platform specific dependencies can be added as well
    ++ lib.optional hostPlatform.isDarwin [
      # If you're getting linker errors about missing libraries, you can add them here
      libiconv
      # If you're getting linker errors about missing frameworks, you can add apple frameworks here
      darwin.apple_sdk.frameworks.Security
    ];
}
