# Capacitor API (scope == floxpkgs)
{
  lib,
  self,
  ...
}:
# User API
{
  # path to catalog json file
  catalogFile ? null,
  # path to catalog directory with json subtrees or leaves
  catalogDirectory ? null,
  # mountpoint in catelog attr
  # catalog.<system>.<stability>[.<path>].<catalog entries>
  path ? [],
  ...
} @ args:
# Plugin API (scope == Using flake)
{context, ...}: let
  fileToDerivationData = path: builtins.fromJSON (builtins.readFile path);

  dirToDerivationData = dir: let
    dirInfo = builtins.readDir dir;
    fileTypeToFuncs = {
      # regular files are leaves
      regular = fileToDerivationData;
      # recurse for directories
      directory = dirToDerivationData;
      symlink = path: throw "symlinks are not supported; cannot add ${path} to catalog";
      unknown = path: throw "cannot add file ${path} with type 'unknown' to catalog";
    };
  in
    lib.mapAttrs'
    (file: fileType: {
      # replace . with _ in attribute names
      name =
        builtins.replaceStrings
        ["."]
        ["_"]
        # remove .json from the attribute name
        (
          if fileType == "regular" && lib.hasSuffix ".json" file
          then lib.strings.removeSuffix ".json" file
          else file
        );
      value = fileTypeToFuncs.${fileType} (builtins.concatStringsSep "/" [dir file]);
    })
    dirInfo;

  derivationDataToFakeDerivation = catalogData:
    lib.capacitor.mapAttrsRecursiveCondFunc
    # premapper:
    # - replace . with _ in attribute names
    # - detect version set (**<package>**.<versions>)
    #   and inject a new attribute `latest`
    #   as an alias to the version most recently updated
    #   Detection is done by finding the same pattern used to stop mapAttrsRecursiveCondFunc
    #   TODO: use `type` attribut
    #   TODO: use refCount as 'freshness attribute because the modification date for a given nixpkgs
    #   commit could bear little resemblance to the date that it was rebased to HEAD, but I get that
    #   we're using that for now because our other catalog publishing mechanism doesn't provide revCount
    (_: b:
      lib.mapAttrs'
      (n: v: let
        isLeafBranch = lib.all (leaf: leaf ? element.storePaths) (lib.attrValues v);
        latest =
          lib.foldl
          (acc: leaf:
            if acc == null || acc.source.locked.lastModified < leaf.source.locked.lastModified
            then leaf
            else acc)
          null
          (lib.attrValues v);
      in {
        name = builtins.replaceStrings ["."] ["_"] n;
        value = v // lib.optionalAttrs isLeafBranch {inherit latest;};
      })
      b)
    # mapper
    (func: x: lib.recurseIntoAttrs (builtins.mapAttrs func x))
    # cond: stop recursing if attribute contains element.outputs
    (_: a: !(a ? element.storePaths))
    # f
    (
      path: x:
      # mapAttrsRecursiveCondFunc calls this function on leaves even if cond is not met (**which deviates from stdlib**), so we
      # have to double check cond
      # TODO: use `type == "flakeRender"` as condition
        if (x ? element.storePaths)
        then
          (self.lib.mkFakeDerivation
            {
              eval =
                (x.eval or {})
                // {
                  meta = {outputsToInstall = ["out"];} // (x.eval.meta or {});
                  outputs = x.eval.outputs or {"out" = lib.head x.element.storePaths;};
                };
              inherit (x) element;
            })
        else throw "encountered a leaf that doesn't have storePaths"
    )
    catalogData;

  catalogFakeDerivations =
    derivationDataToFakeDerivation
    (
      if catalogFile != null && catalogDirectory != null
      then throw "only one of catalogFile and catalogDirectory can be set"
      else if catalogFile != null
      then
        if builtins.pathExists (builtins.unsafeDiscardStringContext catalogFile)
        then fileToDerivationData catalogFile
        else builtins.trace "warning: Could not find defined catalog file at ${(builtins.unsafeDiscardStringContext catalogFile)}" {}
      else if catalogDirectory != null
      then
        if builtins.pathExists (builtins.unsafeDiscardStringContext catalogDirectory)
        then dirToDerivationData catalogDirectory
        else builtins.trace "warning: Could not find defined catalog directory at ${(builtins.unsafeDiscardStringContext catalogDirectory)}" {}
      else if builtins.pathExists (builtins.unsafeDiscardStringContext (context.self + "/catalog"))
      then dirToDerivationData (context.self + "/catalog")
      else {}
    );

  recurseIntoAttrsPath = path: attrset:
    if path == []
    then attrset
    else (lib.recurseIntoAttrs attrset) // {${lib.head path} = recurseIntoAttrsPath (lib.tail path) (attrset.${lib.head path});};
in rec {
  # Assumes: catalog of structure <system>.<stability>.<attrPAth>
  catalog =
    lib.mapAttrs (
      system: catalogForSystem:
        lib.mapAttrs
        (stability: catalogForSystemAndStability:
          recurseIntoAttrsPath
          (lib.flatten [path])
          (lib.setAttrByPath (lib.flatten [path]) catalogForSystemAndStability))
        catalogForSystem
    )
    (builtins.removeAttrs catalogFakeDerivations ["recurseForDerivations"]);
  evalCatalog =
    lib.mapAttrsRecursiveCond
    (v: !(lib.isAttrs v && v ? latest))
    (_: v:
      if lib.isAttrs v
      then v.latest // v
      else v)
    context.self.catalog;
}
