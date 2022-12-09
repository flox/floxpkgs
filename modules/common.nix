{
  config,
  lib,
  pkgs,
  system,
  self,
  ...
}: {
  options = with lib; {
    packages = mkOption {
      # TODO actual type
      type = types.attrsOf types.anything;
      default = {};
    };

    catalogPath = mkOption {
      internal = true;
      type = types.nullOr types.path;
      default = null;
    };

    newCatalogPath = mkOption {
      internal = true;
      type = types.path;
    };

    manifestPath = mkOption {
      internal = true;
      type = types.path;
    };

    ###################
    # Copied from NixOS
    ###################
    system = {
      path = mkOption {
        internal = true;
        # description = lib.mdDoc ''
        #   The packages you want in the boot environment.
        # '';
      };
    };

    environment = {
      systemPackages = mkOption {
        type = types.listOf types.package;
        default = [];
        # example = literalExpression "[ pkgs.firefox pkgs.thunderbird ]";
        # description = lib.mdDoc ''
        #   The set of packages that appear in
        #   /run/current-system/sw.  These packages are
        #   automatically available to all users, and are
        #   automatically updated every time you rebuild the system
        #   configuration.  (The latter is the main difference with
        #   installing them in the default profile,
        #   {file}`/nix/var/nix/profiles/default`.
        # '';
      };
    };
    #######################
    # End copied from NixOS
    #######################
  };

  config = let
    # helper
    notDerivation = x: ! (lib.isDerivation x);

    catalog =
      if config.catalogPath == null
      then {}
      else builtins.fromJSON (builtins.readFile config.catalogPath);

    getCatalogPath = channelName: packageName: packageConfig: [
      channelName
      system
      packageConfig.stability or "stable"
      packageName
      packageConfig.version or "latest"
    ];

    getEvalCatalogPath = packageName: packageConfig: let
      version =
        if packageConfig ? version
        then
          builtins.replaceStrings
          ["."]
          ["_"]
          packageConfig.version
        else "latest";
    in [
      system
      packageConfig.stability or "stable"
      packageName
      version
    ];

    newFakeCatalog =
      builtins.mapAttrs generateChannelFakeCatalog config.packages;

    generateChannelFakeCatalog = channelName: channelPackages: let
      # utility function - should be in lib?
      attrsToList = attrSet:
        map (name: {
          inherit name;
          value = attrSet.${name};
        }) (builtins.attrNames attrSet);
      packagesList = attrsToList channelPackages;
      partitioned =
        builtins.partition (
          packageAttrSet:
            lib.hasAttrByPath (getCatalogPath channelName packageAttrSet.name packageAttrSet.value) catalog
        )
        packagesList;
      alreadyInCatalog =
        builtins.map (
          packageAttrSet: let
            catalogPath = getCatalogPath channelName packageAttrSet.name packageAttrSet.value;
          in
            # channelName will be added elsewhere
            lib.setAttrByPath (builtins.tail catalogPath) (
              self.lib.mkFakeDerivation (lib.getAttrFromPath catalogPath catalog)
            )
        )
        partitioned.right;
      fromChannel = let
        fetchedChannel = let
          # TODO tryEval doesn't actually catch this
          tryFetchChannel = builtins.tryEval (builtins.getFlake channelName);
        in
          if tryFetchChannel.success
          then tryFetchChannel.value
          else throw "No channel ${channelName} found in channel subscriptions; you can subscribe to it with \"flox subscribe\"";

        channelEvalCatalog =
          if builtins.hasAttr "evalCatalog" fetchedChannel
          then fetchedChannel.evalCatalog
          else throw "Channel ${channelName} does not contain a catalog";
      in
        builtins.map (
          packageAttrSet: let
            catalogPath = getCatalogPath channelName packageAttrSet.name packageAttrSet.value;
          in let
            catalogPathWithoutChannel = builtins.tail catalogPath;
            evalCatalogPath = getEvalCatalogPath packageAttrSet.name packageAttrSet.value;
          in
            # this function returns just the entries for this channel, and the caller adds channelName to the complete catalog
            lib.setAttrByPath catalogPathWithoutChannel (
              if lib.hasAttrByPath evalCatalogPath channelEvalCatalog
              then lib.getAttrFromPath evalCatalogPath channelEvalCatalog
              else throw "Channel ${channelName} does not contain ${builtins.concatStringsSep "." catalogPathWithoutChannel}"
            )
        )
        partitioned.wrong;
    in
      builtins.foldl'
      lib.recursiveUpdate
      {}
      (alreadyInCatalog ++ fromChannel);

    # we could check uniqueness in O(n log n) by first sorting all elements by storePaths, but I don't think that's
    # worth my time at the moment
    uniqueFakeCatalog =
      lib.mapAttrsRecursiveCond notDerivation (
        attrPath1: fakeDerivation1:
        # we need to throw if fakeDerivation1 is not unique, but if it is unique, we don't need the
        # result of this computation, so use deepSeq
          builtins.deepSeq (lib.mapAttrsRecursiveCond notDerivation (
              attrPath2: fakeDerivation2:
                if attrPath1 == attrPath2
                then null
                else if
                  (builtins.sort builtins.lessThan fakeDerivation1.meta.element.element.storePaths)
                  == (builtins.sort builtins.lessThan fakeDerivation2.meta.element.element.storePaths)
                then throw "package ${builtins.concatStringsSep "." attrPath1} is identical to package ${builtins.concatStringsSep "." attrPath2}"
                else null
            )
            newFakeCatalog)
          fakeDerivation1
      )
      newFakeCatalog;

    # extract a list of fake derivations
    packagesList =
      lib.collect lib.isDerivation uniqueFakeCatalog;

    # get rid of the fake derivations; we just need meta.element
    newCatalog =
      lib.mapAttrsRecursiveCond notDerivation
      (_: fakeDerivation: fakeDerivation.meta.element or "this catalog doesn't add element to meta")
      uniqueFakeCatalog;
    # turn uniqueFakeCatalog into a backwards compatible manifest.json
    manifestJSON = builtins.toJSON {
      version = 2;
      elements =
        lib.flatten
        (lib.mapAttrsToList (
            channel: systemPackages:
              lib.mapAttrsToList (system: stabilityPackages:
                lib.mapAttrsToList (
                  stability: packagePackages:
                    lib.mapAttrsToList (
                      package: versionPackages:
                        lib.mapAttrsToList (
                          version: fakeDerivation: {
                            inherit (fakeDerivation.meta.element.element) url outputs storePaths;
                            active = true;
                            attrPath = lib.concatStringsSep "." ["evalCatalog" system stability package];
                            originalUrl = "flake:${channel}";
                          }
                        )
                        versionPackages
                    )
                    packagePackages
                )
                stabilityPackages)
              systemPackages
          )
          uniqueFakeCatalog);
    };
  in {
    manifestPath = builtins.toFile "profile" manifestJSON;
    environment.systemPackages = packagesList;
    newCatalogPath = pkgs.writeTextFile {
      name = "catalog.json";
      destination = "/catalog.json";
      text = builtins.unsafeDiscardStringContext (builtins.toJSON newCatalog);
    };

    system.path = pkgs.buildEnv {
      name = "system-path";
      paths = config.environment.systemPackages;
      ignoreCollisions = false;
    };
  };
}
