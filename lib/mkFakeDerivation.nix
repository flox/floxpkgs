# mkFakeDerivation transforms data in catalog format into a fake derivation with a store path that
# can be substituted
{lib}: element: let
  outputs = element.eval.outputs or (throw "unable to create mkFakeDerivation: no eval.outputs");
  outputNames = builtins.attrNames outputs;
  defaultOutput = builtins.head outputNames;
  common =
    {
      name = element.eval.name or "unnamed";
      version = element.eval.version or null;
      pname = element.eval.pname or null;
      meta = element.eval.meta or {};
      system = element.eval.system;
    }
    // outputsSet
    //
    # We want these attributes to have higher precedence than outputsSet since they are critical to
    # the use of the result, and a "type", "all", or "outputs" attribute in outputsSet could override
    # these attributes.
    # Even if "type", "all", or "outputs" from outputsSet get overriden, they will still be accessible
    # via the "all" attribute below since this is a recursive structure
    {
      type = "derivation";
      outputs = outputNames;
      all = outputsList;
    };
  outputToAttrListElement = outputName: {
    name = outputName;
    value =
      common
      // rec {
        inherit outputName;
        outPath = builtins.storePath outputs.${outputName};
      };
  };
  outputsList = map outputToAttrListElement outputNames;
  outputsSet = builtins.listToAttrs outputsList;

  defaultOut = outputsSet.${defaultOutput};
in
  (derivation
    {
      name = defaultOut.name;
      system = element.eval.system;
      builder = "builtin:buildenv";
      manifest = outputsSet.${defaultOutput};
      derivations =
        map (x: ["true" 5 1 outputsSet.${x}]) (defaultOut.meta.outputsToInstall or defaultOut.outputs);
    })
  # `derivation` only takes a few preset arguments and in turn produces an attrset
  # To not confuse `derivation` merge in some optional flake fakeDerivation attributes in afterwards
  // {
    # We ensured all outputsToInstall are wrapped by this buildenv, and this buildenv will only have
    # a single output, so we shouldn't pass outputsToInstall through
    meta = builtins.removeAttrs defaultOut.meta ["outputsToInstall"] // {inherit element;};
    pname = defaultOut.pname;
    version = defaultOut.version;
    fromSource = with element.element; lib.getAttrFromPath attrPath (builtins.getFlake url);
  }
# TODO: fix in Nix, or unification (which does wrapping already)
# TODO: fetchClosure

