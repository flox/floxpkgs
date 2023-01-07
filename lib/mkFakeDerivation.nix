# mkFakeDerivation transforms data in catalog format into a fake derivation with a store path that
# can be substituted
{lib}: element: let
  outputs = element.eval.outputs or (throw "unable to create mkFakeDerivation: no eval.outputs");
  fromSource = with element.element;
    if url == ""
    then throw "url = \"\" so this fakeDerivation can't be built from source. Note that fakeDerivations created from self cannot be built from source"
    else lib.getAttrFromPath attrPath (builtins.getFlake url);
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
        outPath =
          # We could be
          # 1. using an entry from the catalog that has a cache hit
          # 2. using an entry from the catalog that does not have a cache hit and is
          #   a. built locally
          #   b. not built locally
          # 3. an entry from self - not reproducible, so ultimately we'll throw an error
          # For case 2a, it would be preferable if we could try builtins.storePath, but we can't, so
          # just build from source
          if element ? cache
          then
            if builtins.any (cacheMetadata: cacheMetadata.state == "hit") element.cache
            then
              builtins.fetchClosure {
                fromStore = (builtins.head element.cache).cacheUrl;
                fromPath = outputs.${outputName};
              }
            else fromSource.${outputName}
          else fromSource.${outputName};
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
    inherit fromSource;
  }
# TODO: fix in Nix, or unification (which does wrapping already)
# TODO: fetchClosure

