{
  callPackage,
  inputs,
  withRev,
  ...
}:
callPackage inputs.flox {
  revision = "-r${toString inputs.flox.revCount or "dirty"}";
  inherit withRev;
}
