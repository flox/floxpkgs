{
  self,
  callPackage,
  capacitated,
  ...
}:
capacitated.flox.packages.flox // {fromCatalog = self.evalCatalog.stable.flox;}
