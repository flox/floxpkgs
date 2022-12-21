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

    # path getters
    # for channel and flake - a channel has an evalCatalog while a flake does not
    # for catalog and flake - the catalog path is the JSON path in catalog.json, and the flake path is the attribute path to the derivation
    getChannelCatalogPath = channelName: packageAttrPath: packageConfig:
      [
        channelName
        system
        packageConfig.stability or "stable"
      ]
      ++ packageAttrPath
      ++ [
        packageConfig.version or "latest"
      ];

    getChannelFlakePaths = packageAttrPath: packageConfig: let
      version =
        if packageConfig ? version
        then [
          (
            builtins.replaceStrings
            ["."]
            ["_"]
            packageConfig.version
          )
        ]
        else [];
    in [
      (
        [
          "evalCatalog"
          system
          packageConfig.stability or "stable"
        ]
        ++ packageAttrPath
        ++ version
      )
    ];

    getFlakeCatalogPath = channelName: packageAttrPath: _:
      [
        channelName
        system
      ]
      ++ packageAttrPath;

    getFlakeFlakePaths = packageAttrPath: _: [
      ([
          "packages"
          system
        ]
        ++ packageAttrPath)
      ([
          "legacyPackages"
          system
        ]
        ++ packageAttrPath)
    ];

    # utility function - should be in lib?
    # f is a function that takes a name and value and returns a string categorizing that name and
    # value
    groupAttrSetBy = f: attrSet: let
      listWithKeys =
        lib.mapAttrsToList (name: value: let
          groupByString = f name value;
        in {
          "${groupByString}" = {"${name}" = value;};
        })
        attrSet;
    in
      # we have [{groupByString = {name = value};}], and we know every name is unique, so combine
      # all attribute sets with the same groupByString
      builtins.zipAttrsWith (
        _: values:
          builtins.foldl'
          lib.recursiveUpdate
          {}
          values
      )
      listWithKeys;

    groupedChannels =
      groupAttrSetBy (
        channelName: _:
          if lib.isStorePath channelName
          then "storePaths"
          else let
            fetchedChannel = builtins.getFlake channelName;
          in
            if builtins.hasAttr "evalCatalog" fetchedChannel
            then "channels"
            else "flakes"
      )
      config.packages;

    # partially apply generateFakeCatalog to the appropriate getters
    packagesWithDerivation =
      builtins.concatLists (lib.mapAttrsToList (getDerivationsForPackages getChannelCatalogPath getChannelFlakePaths) (groupedChannels.channels or {}))
      ++ builtins.concatLists (lib.mapAttrsToList (getDerivationsForPackages getFlakeCatalogPath getFlakeFlakePaths) (groupedChannels.flakes or {}));
    storePaths = builtins.attrNames (groupedChannels.storePaths or {});

    getDerivationsForPackages = catalogPathGetter: flakePathsGetter: channelName: channelPackages: let
      # in order to support nested packages, we have to recurse until no attributes are attribute
      # sets, or there is a "config" attribute set
      isNotPackageConfig = attrs: ! attrs ? "config" && builtins.any (value: builtins.isAttrs value) (builtins.attrValues attrs);
      # extract a list from the nested configuration format
      # return list of a packagesAttrSets where a packageAttrSet is of the form
      # {
      #   attrPath = ["python3Packages" "requests"];
      #   packageConfig = {
      #     config = {};
      #     version = "1.12";
      #   };
      # };
      packageAttrSetsList = lib.collect (attrs: attrs ? attrPath && attrs ? packageConfig) (lib.mapAttrsRecursiveCond isNotPackageConfig (attrPath: value: {
          inherit attrPath;
          packageConfig = value;
        })
        channelPackages);

      # parition packages based on whether they are already in the catalog
      partitioned =
        builtins.partition (
          packageAttrSet:
            lib.hasAttrByPath (catalogPathGetter channelName packageAttrSet.attrPath packageAttrSet.packageConfig) catalog
        )
        packageAttrSetsList;

      alreadyInCatalog =
        builtins.map (
          packageAttrSet: let
            catalogPath = catalogPathGetter channelName packageAttrSet.attrPath packageAttrSet.packageConfig;
          in rec {
            drv =
              self.lib.mkFakeDerivation (lib.getAttrFromPath catalogPath catalog);
            catalogData = drv.meta.element;
            # for informative error messages
            inherit channelName;
            # for informative error messages
            inherit (packageAttrSet) attrPath;
            inherit catalogPath;
          }
        )
        partitioned.right;
      fromChannel = let
        # todo let readPackage fetch the flake (technically right now there's a race condition)
        fetchedFlake = builtins.getFlake channelName;
      in
        builtins.map (
          packageAttrSet: let
            catalogPath = catalogPathGetter channelName packageAttrSet.attrPath packageAttrSet.packageConfig;
            flakePaths = flakePathsGetter packageAttrSet.attrPath packageAttrSet.packageConfig;
            # find the first flake path that exists in fetchedFlake
            flakePath = let
              maybeFlakePath =
                builtins.foldl' (
                  foundFlakePath: flakePath:
                    if foundFlakePath != []
                    then foundFlakePath
                    else if lib.hasAttrByPath flakePath fetchedFlake
                    then flakePath
                    else []
                ) []
                flakePaths;
            in
              if maybeFlakePath != []
              then maybeFlakePath
              else let
                flakePathsToPrint = builtins.concatStringsSep " or " (builtins.map (flakePath: builtins.concatStringsSep "." flakePath) flakePaths);
              in
                throw "Channel ${channelName} does not contain ${flakePathsToPrint}";
            maybeFakeDerivation = lib.getAttrFromPath flakePath fetchedFlake;
            catalogData =
              if maybeFakeDerivation ? meta.element
              then let
                publishCatalogData =
                  self.lib.readPackage {
                    attrPath = flakePath;
                    flakeRef = channelName;
                    useFloxEnvChanges = true;
                  } {analyzeOutput = false;}
                  maybeFakeDerivation;
              in
                maybeFakeDerivation.meta.element
                // {
                  publish_element = publishCatalogData.element;
                }
              else
                self.lib.readPackage {
                  # TODO use namespace and attrPath instead of passing entire flakePath as attrPath
                  attrPath = flakePath;
                  flakeRef = channelName;
                  useFloxEnvChanges = true;
                } {analyzeOutput = true;}
                maybeFakeDerivation;

            fakeDerivation =
              if maybeFakeDerivation ? meta.element
              then maybeFakeDerivation
              # we have to wrap derivations from flakes in a fake derivation, because that's what
              # will happen once they are put in the catalog. And the floxEnv must be identical for
              # the locking and locked build
              else self.lib.mkFakeDerivation catalogData;
          in
            # this function returns just the entries for this channel, and the caller adds channelName to the complete catalog
            rec {
              drv = fakeDerivation;
              # has publish_element, which fakeDerivation.meta.element does not
              inherit catalogData;
              # for informative error messages
              inherit channelName;
              # for informative error messages
              inherit (packageAttrSet) attrPath;
              inherit catalogPath;
            }
        )
        partitioned.wrong;
    in
      alreadyInCatalog ++ fromChannel;

    # we could check uniqueness in O(n log n) by first sorting all elements by storePaths, but I don't think that's
    # worth my time at the moment
    # instead, for every package, compare to every package and every store path
    uniquePackagesWithDerivation =
      builtins.map (
        packageWithDerivation1:
        # we need to throw if packageWithDerivation1 is not unique, but if it is unique, we don't need the
        # result of this computation, so use deepSeq
        # compare against all packages from flakes and channels
        # TODO use genericClosure instead?
          builtins.deepSeq (builtins.map (
              packageWithDerivation2:
                if packageWithDerivation1.catalogPath == packageWithDerivation2.catalogPath
                then null
                else if
                  (builtins.sort builtins.lessThan packageWithDerivation1.catalogData.element.storePaths)
                  == (builtins.sort builtins.lessThan packageWithDerivation2.catalogData.element.storePaths)
                then throw "package ${builtins.concatStringsSep "." packageWithDerivation1.catalogPath} is identical to package ${builtins.concatStringsSep "." packageWithDerivation2.catalogPath}"
                else null
            )
            packagesWithDerivation)
          # compare against storePaths
          (builtins.deepSeq
            (builtins.map (
                storePath:
                  if packageWithDerivation1.catalogData.element.storePaths == [storePath]
                  then throw "package ${builtins.concatStringsSep "." packageWithDerivation1.catalogPath} is identical to store path ${storePath}"
                  else null
              )
              storePaths)
            # pass packageWithDerivation1 through the map - in other words, do nothing
            packageWithDerivation1)
      )
      packagesWithDerivation;

    sortedPackagesWithDerivation = builtins.sort (packageWithDerivation1: packageWithDerivation2: packageWithDerivation1.catalogPath < packageWithDerivation2.catalogPath) uniquePackagesWithDerivation;

    # since storePaths are specified in the attrPath, we don't need to check for uniqueness
    sortedStorePaths = builtins.sort (storePath1: storePath2: storePath1 < storePath2) storePaths;

    # extract a list of derivations
    packagesList =
      builtins.map (packageWithDerivation: packageWithDerivation.drv) sortedPackagesWithDerivation
      # types.package calls builtins.storePath
      ++ sortedStorePaths;

    # store paths are not added to the catalog
    newCatalog =
      builtins.foldl' lib.recursiveUpdate {}
      (builtins.map
        (packageWithDerivation:
          lib.setAttrByPath
          packageWithDerivation.catalogPath
          packageWithDerivation.catalogData)
        sortedPackagesWithDerivation);

    # For flake:
    # {
    #   "active": true,
    #   "attrPath": "legacyPackages.aarch64-darwin.hello",
    #   "originalUrl": "flake:nixpkgs",
    #   "outputs": null,
    #   "priority": 5,
    #   "storePaths": [
    #     "/nix/store/gq5b6y0zxvpfxywi600ahlcg3mnscv93-hello-2.12.1"
    #   ],
    #   "url": "github:flox/nixpkgs/2788904d26dda6cfa1921c5abb7a2466ffe3cb8c"
    # }

    # For channel:
    # {
    #   "active": true,
    #   "attrPath": "evalCatalog.aarch64-darwin.stable.hello",
    #   "originalUrl": "flake:nixpkgs-flox",
    #   "outputs": null,
    #   "priority": 5,
    #   "storePaths": [
    #     "/nix/store/lc9cci22gfxd7xaqjdvz3kkd09g4g0g7-hello-2.12.1"
    #   ],
    #   "url": "github:flox/nixpkgs-flox/5cdedb611cf745c734b0268346e940a8b1e33b45"
    # },
    packageManifestElements =
      builtins.map (
        packageWithDerivation: let
          element =
            # if this is a publish of a publish, use it
            packageWithDerivation.catalogData.publish_element
            or packageWithDerivation.catalogData.element;
        in {
          active = true;
          inherit (element) url originalUrl storePaths;
          attrPath = builtins.concatStringsSep "." element.attrPath;
          outputs = element.outputs or null;
        }
      )
      # manifest.json needs to have a non-random ordering for flox list
      sortedPackagesWithDerivation;
    storePathManifestElements =
      builtins.map (storePath: {
        active = true;
        storePaths = [
          storePath
        ];
      })
      sortedStorePaths;

    manifestJSON = builtins.toJSON {
      version = 2;
      elements = packageManifestElements ++ storePathManifestElements;
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
