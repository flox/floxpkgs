{
  self,
  callPackage,
  capacitated,
  lib,
  ...
}:
lib.lazyDerivation { 
  derivation = capacitated.flox.packages.flox;
  passthru = {
    fromCatalog = self.evalCatalog.stable.flox;
  };
}
