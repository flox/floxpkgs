# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

let

# ---------------------------------------------------------------------------- #

  # Regex match predicate.
  test = patt: s: ( builtins.match patt s ) != null;

  reFId    = "[a-zA-Z][a-zA-Z0-9_-]*";
  reScheme = "((([^:+]+)\\+)?([^+:]+)):";
  reRel    = "([^/?]+)/([^/?]+)(/?([^?]+))?";
  reURI    = "(${reScheme})?(${reRel}|/[^?]+|[^?]+)(\\?(.*))?";
  reTB     = "zip|tar|tgz|tar.gz|tar.xz|tar.bz2|tar.zst";
  reRev    = "[[:xdigit:]]{40}";

  # Maps URI data scheme prefixes to their associate `builtins.fetchTree' type.
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

  # Reversed lookup table.
  typeToDataScheme = builtins.listToAttrs (
    map ( value: {
      name = builtins.getAttr value dataSchemeToType;
      inherit value;
    } ) ( builtins.attrNames dataSchemeToType )
  );


# ---------------------------------------------------------------------------- #

  # A naive `Any -> String' routine that does not recurse into containers.
  toPretty = x: let
    str = {
      lambda = "<LAMBDA>";
      set    = let
        o = if ( x.type or null ) != "derivation"
            then removeAttrs x ["outPath"]
            else removeAttrs x ["outPath" "type"];
      in builtins.toJSON o;
      list = builtins.toJSON x;
      null = "null";
    }.${builtins.typeOf x} or ( toString x );
  in builtins.unsafeDiscardStringContext str;


# ---------------------------------------------------------------------------- #

  # Helper used to extract `rev' and `ref' strings.
  tagRefOrRev = r:
    assert builtins.isString r;
    if test reRev r then { rev = r; } else { ref = r; };


# ---------------------------------------------------------------------------- #

  # Split a URI query string into an attribute set.
  # Parameters without values will be set to `null' - all other values are
  # emitted as strings.
  #
  # Ex:
  # paramStrToAttrs "foo=1&bar&quux=3" -> { foo = "1"; bar = null; quux = "3"; }
  paramStrToAttrs = str: let
    sp   = builtins.split "[?&]" str;
    proc = acc: x: let
      xs = builtins.match "([^=]+)(=(.*))?" x;
    in if ( builtins.isList x ) || ( xs == null ) then acc else acc ++ [{
      name = builtins.head xs; value = builtins.elemAt xs 2;
    }];
    rsl = if builtins.elem str ["?" ""] then {} else
          builtins.listToAttrs ( builtins.foldl' proc [] sp );
    pretty = toPretty str;
  in assert builtins.isString str;
     builtins.addErrorContext "Parsing query string `${pretty}'" rsl;

  # Join an attribute set of strings/nulls into a URI query string.
  # Attributes with `null' values are written as `<NAME>&...', and attributes
  # with string values are written as `<NAME>=<VALUE>&...`
  #
  # Ex:
  # paramStrToAttrs { foo = "1"; bar = null; quux = "3"; } -> "foo=1&bar&quux=3"
  paramAttrsToStr = attrs: let
    proc = name: let
      val = builtins.getAttr name attrs;
    in if val == null then name else "${name}=${toString val}";
  in assert builtins.isAttrs attrs;
     builtins.concatStringsSep "&" ( map proc ( builtins.attrNames attrs ) );


# ---------------------------------------------------------------------------- #

  # Identify a URI string's `builtins.fetchTree' input `type' ( scheme ).
  identifyURIType = ref: let
    m                 = builtins.match reURI ref;
    explicitTransport = ( builtins.elemAt m 3 ) != null;
    data              = let
      f = builtins.elemAt m 3;
      s = if f == null then builtins.elemAt m 4 else f;
    in if builtins.elem s ["http" "https"] then null else s;
    path = builtins.elemAt m 5;
    fst  = builtins.substring 0 1 path;
    dt   = if data == null then null else
           builtins.getAttr data dataSchemeToType;
    # The `file' scheme is ambiguous because it can be indicating either
    # data or transport scheme.
    # Specifically you may write `tarball+file:///foo.tgz' as `file:///foo.tgz'
    # For this scheme we have to double check for a tarball suffix.
    hasTbSuffix = test ".*(${reTB})" path;
    handleFile  = if ( dt != "file" ) || explicitTransport then dt else
                  if hasTbSuffix then "tarball" else "file";
    pretty = toPretty ref;
    rsl    =
      if data != null then handleFile else
      if test ".*(https?|file):.*" ref
      then ( if hasTbSuffix             then "tarball"  else "file" )
      else if test "${reFId}(/.*)?" ref then "indirect" else
           throw "`${pretty}' is not a valid URL.";
  in assert builtins.isString ref;
     builtins.addErrorContext "Identifying URI type of `${ref}'." rsl;


# ---------------------------------------------------------------------------- #

  # Parse a flake-ref string to an attribute set like those accepted by
  # `flake' inputs and `builtins.fetchTree'.
  #
  # Ex:
  # flakeRefStrToAttrs "git+ssh://git@github.com/NixOS/nixpkgs.git?dir=aa&x&y=2"
  # ->
  # { dir  = "aa";
  #   type = "git";
  #   url  = "ssh://git@github.com/NixOS/nixpkgs.git?x&y=2";
  # }
  flakeRefStrToAttrs = let
    # Parameters to extract from queries to be converted to attributes.
    exParams = {
      # All
      flake = true;
      dir   = true;
      # URL
      narHash = true;
      # Git-Like
      rev  = true;
      ref  = true;
      host = true;
      # Git
      allRefs    = true;
      shallow    = true;
      submodules = true;
    };
  in ref: let
    m = builtins.match reURI ref;
    # Extract parameters, removing some that are processed only by `nix'.
    pa  = builtins.elemAt m 11;
    pa' = if pa == null then {} else paramStrToAttrs pa;
    pk' = builtins.intersectAttrs exParams pa';
    pr' = builtins.removeAttrs pa' ( builtins.attrNames exParams );
    # Reconstruct a parameter string without special variables.
    ps'  = paramAttrsToStr pr';
    type = identifyURIType ref;
    path = builtins.elemAt m 5;
    base = { inherit type; } // pk';
    # Indirect
    forIndirect = let
      m' = builtins.match "(flake:)?([^/]+)(/([^?]+))?(\\?.*)?" ref;
      r  = builtins.elemAt m' 3;
    in ( if r == null then {} else tagRefOrRev r ) // {
      id = builtins.elemAt m' 1;
    };
    # GitHub, SourceHut, GitLab with `owner' and `repo' fields.
    forGHLike = let
      r = builtins.elemAt m 9;
    in ( if r == null then {} else tagRefOrRev r ) // {
      owner = builtins.elemAt m 6;
      repo  = builtins.elemAt m 7;
    };
    # Strip off special params like `narHash' and `rev' from `url'.
    forUrl.url = ( builtins.elemAt m 4 ) + ":" + path +
                 ( if ps' == "" then "" else "?" + ps' );
    # Looks for `.*.git/<REF-OR-REV>' otherwise same as `forUrl'.
    forGit = let
      m'   = builtins.match "(.*\\.git)(/(.*))?" path;
      r    = builtins.elemAt m' 2;
    in if ( m' == null ) || ( r == null ) then forUrl else tagRefOrRev r // {
      url = ( builtins.elemAt m 4 ) + ":" + ( builtins.head m' ) +
            ( if ps' == "" then "" else "?" + ps' );
    };
    forT =
      if type == "indirect" then forIndirect       else
      if type == "path"     then { inherit path; } else
      if type == "git"      then forGit            else
      if builtins.elem type ["github" "sourcehut" "gitlab"] then forGHLike else
      forUrl;
    rsl = if ( m == null ) && ( type != "indirect" )
          then throw ( "Invalid URI: " + ref )
          else base // forT;
    pretty = toPretty ref;
  in assert builtins.isString ref;
     builtins.addErrorContext "Converting flakeref `${pretty}' to attributes."
     rsl;


# ---------------------------------------------------------------------------- #

  # Convert an attribute set representing a flake-ref into a URI string.
  flakeRefAttrsToStr = attrs: let
    pathQ = builtins.getAttr attrs.type {
      inherit (attrs) path;
      tarball   = attrs.url;
      file      = attrs.url;
      git       = attrs.url;
      mercurial = attrs.url;
      github    = attrs.owner + "/" + attrs.repo;
      gitlab    = attrs.owner + "/" + attrs.repo;
      sourcehut = attrs.owner + "/" + attrs.repo;
      indirect  = attrs.id;
    };
    pm   = builtins.match "([^?]+)(\\?(.*))?" pathQ;
    path = builtins.head pm;
    # Prepare query string by moving some attributes into parameters.
    # Merge with any existing query in `path'.
    eq  = builtins.elemAt pm 2;
    eqa = if eq == null then {} else paramStrToAttrs eq;
    qa  = eqa // ( removeAttrs attrs [
      "type" "id" "ref" "rev" "owner" "repo" "url" "path"
    ] );
    qs' = paramAttrsToStr qa;
    qs  = if qs' == "" then "" else "?" + qs';
    # Add scheme prefix
    data = builtins.getAttr attrs.type typeToDataScheme;
    # Add `data' scheme.
    # Watch out for some URIs that are invalid if you repeat `data' twice
    # instead of providing a valid transport.
    # This is a side effect of `file' being both a `data' and `transport' scheme
    # and `git'/`hg' leaving it's transport scheme as optional.
    # We just handle a few of the ones that can appear for valid URI attrsets
    # instead of an exhaustive handler.
    # NOTE: `file+file' IS VALID - do not fix it up!
    # We need this to remain unambiguous when we want to fetch a local tarball
    # as a file instead of unpacking it.
    base = let
      wdata = if ( test ".*:.*" path ) then data + "+" + path else
              data + ":" + path;
    in builtins.replaceStrings ["tarball+tarball" "git+git" "hg+hg"]
                               ["tarball"         "git"     "hg"]
                               wdata;
    # Add `refOrRev'
    rr = attrs.rev or attrs.ref or null;
    wr = if rr == null then base else base + "/" + rr;
    pretty = toPretty attrs;
  in assert builtins.isAttrs attrs;
     builtins.addErrorContext "Converting flakeref `${pretty}' to a string."
     ( wr + qs );


# ---------------------------------------------------------------------------- #

  # Given a flake-ref as a string or attrset, parse/stringize the ref, fetch
  # the associated flake, and create a locked form of the ref.
  # This routine mirrors the behavior of `lockFlake` defined by
  # `<github:NixOS/nix>/src/libexpr/flake.hh' except that this routine omits
  # the `resolvedRef' information, and stashes refs at the top level.
  lockFlake = let
    mkRef = r: assert ( builtins.isString r ) || ( builtins.isAttrs r ); {
      attrs  = if builtins.isString r then flakeRefStrToAttrs r else r;
      string = if builtins.isString r then r else flakeRefAttrsToStr r;
    };
  in ref: let
    originalRef = mkRef ref;
    # Fetch the flake to extract locked `sourceInfo' fields.
    flake = builtins.getFlake originalRef.string;
    keeps = if builtins.elem originalRef.attrs.type ["tarball" "file"]
            then { rev = true; narHash = true; }
            else { rev = true; };
    lockedAttrs = ( removeAttrs originalRef.attrs ["ref"] ) //
                  ( builtins.intersectAttrs keeps flake.sourceInfo );
    pretty = toPretty ref;
  in assert ( builtins.isString ref ) || ( builtins.isAttrs ref );
     builtins.addErrorContext "Locking flakeref `${pretty}'." {
       inherit flake originalRef;
       lockedRef = mkRef lockedAttrs;
     };


# ---------------------------------------------------------------------------- #

in {
  inherit
    reURI
    paramStrToAttrs paramAttrsToStr
    identifyURIType
    flakeRefStrToAttrs flakeRefAttrsToStr
    lockFlake
  ;
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
