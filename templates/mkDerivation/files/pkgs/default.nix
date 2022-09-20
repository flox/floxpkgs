# Replace "stdenv" with the namespace or name of your language's builder
{ self, stdenv }:
# Replace "stdenv.mkDerivation" with your language's builder
stdenv.mkDerivation {
  pname = "my-package";
  version = "0.0.0";
  src = self; # + "/src";

  # Add runtime dependencies to buildInputs.
  buildInputs = [];

  # Add runtime dependencies required by packages that
  # depend on this package to propagatedBuildInputs.
  propagatedBuildInputs = [];

  # Add buildtime dependencies (not required at runtime)
  # to nativeBuildInputs.
  nativeBuildInputs = [];
}
