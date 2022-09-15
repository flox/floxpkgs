# Replace "stdenv" with the namespace or name of your language's builder
{stdenv}:
# Replace "stdenv.mkDerivation" with your language's builder
stdenv.mkDerivation {
  name = "my-package";
  src = ../.;

  # Add any dependencies your software needs at runtime to propagatedBuildInputs
  propagatedBuildInputs = [];

  # Add any dependencies your software only needs at buildtime to buildInputs
  buildInputs = [];
}
