{
  self,
  capacitated,
  ...
}:
{
  type = "derivation";
  meta = capacitated.flox.packages.flox.meta;
  inherit (capacitated.flox.packages.flox) outputs out man outPath outputName drvPath name system;
  fromCatalog = self.evalCatalog.stable.flox;
}
