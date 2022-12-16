{...}: {
  packages = {
    "github:nixos/nixpkgs".python3Packages.requests = {};
    nixpkgs-flox.hello = {};
  };
}
