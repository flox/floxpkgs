{rustPlatform}:
rustPlatform.buildRustPackage rec {
  name = "my-package";
  src = ../.;
  cargoLock.lockFile = ../Cargo.lock;
}
