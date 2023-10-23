/*
Re-export flox as a "lazy" derivation with an additional attribute `fromCatalog`

Adding an attribute to a canonical re-export such as

    { inputs }:
      inputs.flox-latest.packages.flox // {fromCatalog = self.evalCatalog.stable.flox; }

requires the evaluation of `inputs.flox-latest.packages.flox` to an attrset.

We want to allow installing packages from the catalog explicitly without any evaluation of the
upstream package (which involves fetching any number of additional flakes).
*/
{
  self,
  inputs,
  ...
}: {
  type = "derivation";

  # re-export outputs and derivation attributes to allow building
  inherit (inputs.flox-latest.packages.flox) outputs out man outPath outputName drvPath name system;

  # re-export metadata
  meta = inputs.flox-latest.packages.flox.meta;

  # add additional attribute
  fromCatalog = self.evalCatalog.stable.flox;
}
