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

    toplevel = mkOption {
      type = types.package;
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
          in
            # this function returns just the entries for this channel, and the caller adds channelName to the complete catalog
            lib.setAttrByPath catalogPathWithoutChannel (
              if lib.hasAttrByPath catalogPathWithoutChannel channelEvalCatalog
              then lib.getAttrFromPath catalogPathWithoutChannel channelEvalCatalog
              else throw "Channel ${channelName} does not contain ${builtins.concatStringsSep "." catalogPathWithoutChannel}"
            )
        )
        partitioned.wrong;
    in
      builtins.foldl'
      lib.recursiveUpdate
      {}
      (alreadyInCatalog ++ fromChannel);

    # extract a list of fake derivations
    packagesList =
      lib.collect lib.isDerivation newFakeCatalog;

    # get rid of the fake derivations; we just need meta.element
    newCatalog =
      lib.mapAttrsRecursiveCond (x: ! (lib.isDerivation x))
      (_: fakeDerivation: fakeDerivation.meta.element or "this catalog doesn't add element to meta")
      newFakeCatalog;
  in {
    environment.systemPackages = packagesList;
    newCatalogPath = builtins.toFile "catalog.json" (builtins.unsafeDiscardStringContext (builtins.toJSON newCatalog));

    system.path = pkgs.buildEnv {
      name = "system-path";
      paths = config.environment.systemPackages;
      ignoreCollisions = true;
    };

    toplevel = pkgs.stdenvNoCC.mkDerivation {
      name = "floxEnv";
      buildCommand = ''
        mkdir $out
        ln -s ${config.system.path} $out/sw
        ln -s ${config.newCatalogPath} $out/catalog.json
        touch $out/activate
      '';
    };
  };
}
