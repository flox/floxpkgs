{ stdenv, fetchFromGitHub, help2man }:

stdenv.mkDerivation rec {
  name = "tracelinks";
  src =
    fetchFromGitHub {
    owner = "flox";
    repo = "tracelinks";
    rev =
  builtins.trace ''
# Note: tracelinks requires access to source code to build from scratch
# Either obtain access to repo via a netrc or perform the following with SSH access:
#
#   nix eval git+ssh://git@github.com/flox/tracelinks?ref=main#
#
# it should provide an error about not finding a file, after that perform a build
  '' "22d985d2757f1834ee51d3dadc93908c9cfc9ab3";
    sha256 = "sha256-RdD0fUS1XT03T4XSp4abxb8AOkQUEy93I86xBkks/Tc=";
  };

  nativeBuildInputs = [ help2man ];
  makeFlags = [ "PREFIX=$(out)" ];
}
