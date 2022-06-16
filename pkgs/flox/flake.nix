{
  inputs.src.url = "git+ssh://git@github.com/flox/flox?ref=tng";
  inputs.src.flake = false;

  outputs = _:
    _.capacitor _ ({lib, ...}:
      #
      # copy proto-derivation here
      #
      {
        callPackage,
        src,
        ...
      }: callPackage src { revision = "-r${toString src.revCount or "dirty"}"; }
      );
}
