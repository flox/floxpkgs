# Capacitor API (scope == floxpkgs)
{lib, ...}:
# User API
# -- no user input required --
{
  catalog,
  system,
  path ? [],
}:
# Plugin API (scope == Using flake)
{context, ...}: let
  catalogData = builtins.fromJSON (builtins.readFile "${catalog}/catalog.json");
  catalogFakeDerivations =
    lib.capacitor.mapAttrsRecursiveCondFunc
    (a: b:
      lib.mapAttrs' (n: v: {
        name = builtins.replaceStrings ["."] ["_"] n;
        value = v;
      })
      b)
    (func: x: lib.recurseIntoAttrs (builtins.mapAttrs func x))
    (_: a: !(a ? element && a.element ? outputs))
    (
      path: x:
        if x ? element && x.element ? outputs
        then
          lib.capacitor.mkFakeDerivation {
            eval = {
              outputs = {"out" = lib.head x.element.storePaths;};
            };
          }
        else x
    )
    catalogData;
in {
  catalog.${system} = lib.setAttrByPath (lib.flatten [path]) catalogFakeDerivations;
}
