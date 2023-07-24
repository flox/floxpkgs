/*
Re-export flox as a "lazy" derivation with an additional attribute `fromCatalog`

Adding an attribute to a canonical re-export such as

    { capacitated }:
      capacitated.flox-latest.packages.flox // {fromCatalog = self.evalCatalog.stable.flox; }

requires the evaluation of `capacitated.flox-latest.packages.flox` to an attrset.

We want to allow installin packages from the catalog explicitly without any evaluation of the
upstream package (which involves fetching any number of additional flakes).
*/

{
  self,
  capacitated,
  ...
}:
{
  type = "derivation";

  # re-export outputs and derivation attributes to allow building
  inherit (capacitated.flox-latest.packages.flox) outputs out man outPath outputName drvPath name system;

  # re-export metadata
  meta = capacitated.flox-latest.packages.flox.meta;

  # add additional attribute
  fromCatalog = self.evalCatalog.stable.flox;
}
