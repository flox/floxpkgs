{
  callPackage,
  inputs,
  withRev,
}:
(callPackage "${inputs.tracelinks}/pkgs/tracelinks/default.nix" {
  self = inputs.tracelinks;
  inherit withRev;
})
.overrideAttrs (oldAttrs: rec {
  # HACK: lock this at 1.0.0 until fixed
  version = "1.0.0-r${toString inputs.tracelinks.revCount or "dirty"}";
})
