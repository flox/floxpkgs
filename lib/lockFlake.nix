# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

let

# ---------------------------------------------------------------------------- #

  test = patt: s: ( builtins.match patt s ) != null;

  reFId    = "[a-zA-Z][a-zA-Z0-9_-]*";
  reScheme = "((([^:+]+)\\+)?([^+:]+)):";
  reRel    = "([^/?]+)/([^/?]+)(/?([^?]+))?";
  reURI    = "(${reScheme})?(${reRel}|/[^?]+)(\\?(.*))?";
  reTB     = "zip|tar|tgz|tar.gz|tar.xz|tar.bz2|tar.zst";
  reRev    = "[[:xdigit:]]{40}";

  dataSchemeToType = {
    hg        = "mercurial";
    flake     = "indirect";
    git       = "git";
    file      = "file";
    tarball   = "tarball";
    github    = "github";
    gitlab    = "gitlab";
    sourcehut = "sourcehut";
    path      = "path";
  };


# ---------------------------------------------------------------------------- #

  # Helper used to extract `rev' and `ref' strings.
  tagRefOrRev = r:
    assert builtins.isString r;
    if test reRev r then { rev = r; } else { ref = r; };


# ---------------------------------------------------------------------------- #

  paramStrToAttrs = str: let
    sp   = builtins.split "[?&]" str;
    proc = acc: x: let
      xs = builtins.match "([^=]+)(=(.*))?" x;
    in if builtins.isList x then acc else acc ++ [{
      name = builtins.head xs; value = builtins.elemAt xs 2;
    }];
  in assert builtins.isString str;
     if builtins.elem str ["?" ""] then {} else
     builtins.listToAttrs ( builtins.foldl' proc [] sp );

  attrsToParamStr = attrs: let
    proc = name: let
      val = builtins.getAttr name attrs;
    in if val == null then name else "${name}=${toString val}";
  in assert builtins.isAttrs attrs;
     builtins.concatStringsSep "&" ( map proc ( builtins.attrNames attrs ) );


# ---------------------------------------------------------------------------- #

  identifyURIType = ref: let
    m = builtins.match reURI ref;
    data = let
      f = builtins.elemAt m 3;
      s = if f == null then builtins.elemAt m 4 else f;
    in if builtins.elem s ["http" "https"] then null else f;
    path = builtins.elemAt m 5;
    fst  = builtins.substring 0 1 path;
  in assert builtins.isString ref;
     if data != null then builtins.getAttr data dataSchemeToType else
     if test ".:*" ref
     then ( if test ".*(${reTB})" path     then "tarball" else "file"     )
     else ( if builtins.elem fst ["/" "."] then "path"    else "indirect" );


# ---------------------------------------------------------------------------- #

  # NOTE: This function only targets InputScheme types that we care about.
  # For example, `mercurial' and `sourcehut' will likely be incorrectly
  # identified as `git' or `github' inputs.
  # Additionally, `tarball' inputs will likely be misinterpreted as `path'.
  identifySourceInfoType = sourceInfo:
    assert builtins.isAttrs sourceInfo;
     if sourceInfo ? revCount then "git"    else
     if sourceInfo ? rev      then "github" else
     if builtins.pathExits ( sourceInfo.outPath + "/." ) then "path" else
     "file";


# ---------------------------------------------------------------------------- #

  # Ex:
  # flakeRefStrToAttrs "git+ssh://git@github.com/NixOS/nixpkgs.git?dir=lib&x&y=2"
  # { dir = "lib"; type = "git"; url = "ssh://git@github.com/NixOS/nixpkgs.git?x&y=2"; }
  flakeRefStrToAttrs = let
    exParams = { dir = true; rev = true; ref = true; narHash = true; };
  in ref: let
    m = builtins.match reURI ref;
    # Extract parameters, removing some that are processed only by `nix'.
    pa  = builtins.elemAt m 11;
    pa' = if pa == null then {} else paramStrToAttrs pa;
    pk' = builtins.intersectAttrs exParams pa';
    pr' = builtins.removeAttrs pa' ( builtins.attrNames exParams );
    # Reconstruct a parameter string without special variables.
    ps'  = attrsToParamStr pr';
    type = identifyURIType ref;
    path = builtins.elemAt m 5;
    base = { inherit type; } // pk';
    # GitHub, SourceHut, GitLab with `owner' and `repo' fields.
    forGHLike = let
      r = builtins.elemAt m 8;
    in ( if r == null then {} else tagRefOrRev r ) // {
      owner = builtins.elemAt 6;
      repo  = builtins.elemAt 7;
    };
    # Strip off special params like `narHash' and `rev' from `url'.
    forUrl.url = ( builtins.elemAt m 4 ) + ":" + path +
                 ( if ps' == "" then "" else "?" + ps' );
    # Looks for `.*.git/<REF-OR-REV>' otherwise same as `forUrl'.
    forGit = let
      m' = builtins.match "(.*\\.git)(/(.*))?" path;
      r  = builtins.elemAt m' 2;
    in if r == null then forUrl else tagRefOrRev r // {
      url = ( builtins.elemAt m 4 ) + ":" + ( builtins.head m' ) +
            ( if ps' == "" then "" else "?" + ps' );
    };
    forT =
      if type == "path" then { inherit path; } else
      if type == "git"  then forGit else
      if builtins.elem type ["github" "sourcehut" "gitlab"] then forGHLike else
      forUrl;
  in assert builtins.isString ref;
     if m == null then throw ( "Invalid URI: " + ref ) else base // forT;

# ---------------------------------------------------------------------------- #

  flakeRefAttrsToStr = attrs: let

  in assert builtins.isAttrs attrs;
     null;


# ---------------------------------------------------------------------------- #

/*
  lockFlake = let

    mkRef = r: assert ( builtins.isString r ) || ( builtins.isAttrs r ); {
      attrs  = if builtins.isString r then liburi.parseFlakeRefFT r else r;
      string = if builtins.isString r then r else
               liburi.flakeRefAttrsToString r;
    };
  in flakeRef: let
    originalRef = mkRef flakeRef;
    flake       = builtins.getFlake originalRef.string;
    keeps       = if builtins.elem originalRef.attrs.type ["tarball" "file"]
                  then { rev = true; narHash = true; }
                  else { rev = true; };
    lockedAttrs = ( removeAttrs originalRef.attrs ["ref"] ) //
                  ( builtins.intersectAttrs keeps flake.sourceInfo );
  in builtins.addErrorContext "Locking flakeref `${builtins.toJSON flakeRef}'" {
    inherit originalRef;
    lockedRef = mkRef lockedAttrs;
  };
*/


# ---------------------------------------------------------------------------- #

in {
  inherit
    reURI
    paramStrToAttrs attrsToParamStr
    identifyURIType identifySourceInfoType
    flakeRefStrToAttrs flakeRefAttrsToStr
  ;
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
