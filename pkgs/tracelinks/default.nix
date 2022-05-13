{
  stdenv,
  help2man,
  fetchFrom,
  inputs,
} @ args:
stdenv.mkDerivation rec {
  pname = "tracelinks";
  version = "1.0.0+r${toString src.lock.revCount}";

  src = fetchFrom inputs "git+ssh://git@github.com/flox/tracelinks?ref=main";

  # Prevent the source from becoming a runtime dependeny
  disallowedReferences = [src.outPath];
  nativeBuildInputs = [help2man];
  makeFlags = ["PREFIX=$(out)"];
}
