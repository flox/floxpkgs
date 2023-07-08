# ============================================================================ #
#
# Audits interfaces in `../lockFlake.nix'.
#
# Run tests from the CLI using:
#   # Quick pass/fail check
#   (flox|nix) eval -f ./lockFlake.nix check;
#
#   # See details about failures
#   (flox|nix) eval -f ./lockFlake.nix failures;
#
#   # As derivation ( great for `flake.nix' checks )
#   (flox|nix) build -f ./lockFlake.nix checkDrv --keep-failed && cat ./result;
#
#
# Additional outputs `fns', `lib', and `tests' are provided for interactive
# usage with `[flox ]nix repl'.
#
#
# ---------------------------------------------------------------------------- #

let

  nixpkgs = let
    rev = "b183dcf7682101cbdf27253bb4ee8377d6213461";  # 23.05 on 7/7/2023
  in builtins.getFlake "github:NixOS/nixpkgs/${rev}";

in { lib ? nixpkgs.lib }: let

# ---------------------------------------------------------------------------- #

  inherit (import ../lockFlake.nix)
    paramStrToAttrs paramAttrsToStr
    identifyURIType
    flakeRefStrToAttrs flakeRefAttrsToStr
    lockFlake
  ;

  # A shorthand for a failed `builtins.tryEval' return.
  FAIL = { success = false; value = false; };


# ---------------------------------------------------------------------------- #

  paramStrToAttrsTests = {

    empty = {
      expr     = paramStrToAttrs "";
      expected = {};
    };

    emptyQM = {
      expr     = paramStrToAttrs "?";
      expected = {};
    };

    noValue = {
      expr     = paramStrToAttrs "x&y&z";
      expected = { x = null; y = null; z = null; };
    };

    # Ensure that a spurious "?" prefix is ignored.
    qmPrefix = {
      expr     = paramStrToAttrs "?x&y&z";
      expected = { x = null; y = null; z = null; };
    };

    # Ensure that a spurious "&" suffix is ignored.
    andSuffix = {
      expr     = paramStrToAttrs "x&y&z&";
      expected = { x = null; y = null; z = null; };
    };

    values = {
      expr     = paramStrToAttrs "x=1&y=2&z=3";
      expected = { x = "1"; y = "2"; z = "3"; };
    };

    mixed = {
      expr     = paramStrToAttrs "x=1&y&z=3";
      expected = { x = "1"; y = null; z = "3"; };
    };

  };  /* End `paramStrToAttrsTests' */


# ---------------------------------------------------------------------------- #

  paramAttrsToStrTests = {

    empty = {
      expr     = paramAttrsToStr {};
      expected = "";
    };

    noValue = {
      expr     = paramAttrsToStr { x = null; y = null; z = null; };
      expected = "x&y&z";
    };

    values = {
      expr     = paramAttrsToStr { x = "1"; y = "2"; z = "3"; };
      expected = "x=1&y=2&z=3";
    };

    mixed = {
      expr     = paramAttrsToStr { x = "1"; y = null; z = "3"; };
      expected = "x=1&y&z=3";
    };

  };  /* End `paramAttrsToStrTests' */


# ---------------------------------------------------------------------------- #

  identifyURITypeTests = let
    apply = _: { expr, ... } @ test: test // { expr = identifyURIType expr; };
  in builtins.mapAttrs apply {

    indirect0 = { expr = "nixpkgs"; expected = "indirect"; };
    indirect1 = {
      expr     = "nixpkgs/a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
      expected = "indirect";
    };
    indirect2 = { expr = "nixpkgs/REF";   expected = "indirect"; };
    indirect3 = { expr = "flake:nixpkgs"; expected = "indirect"; };
    indirect4 = {
      expr     = "flake:nixpkgs?dir=lib";
      expected = "indirect";
    };
    indirect5 = {
      expr     = "flake:nixpkgs/a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
      expected = "indirect";
    };
    indirect6 = { expr = "flake:nixpkgs/REF";         expected = "indirect"; };
    indirect7 = { expr = "flake:nixpkgs/REF?dir=lib"; expected = "indirect"; };


    path0 = { expr = "path:/foo";          expected = "path"; };
    path1 = { expr = "path:/foo/bar";      expected = "path"; };
    path2 = { expr = "path:/foo/bar/baz";  expected = "path"; };
    path3 = { expr = "path:./foo";         expected = "path"; };
    path4 = { expr = "path:./foo/bar";     expected = "path"; };
    path5 = { expr = "path:./foo/bar/baz"; expected = "path"; };


    # These LOOK like `path', but are actually invalid.
    fail0 = { expr = "./foo";                 expected = FAIL; };
    fail1 = { expr = ".";                     expected = FAIL; };
    fail2 = { expr = "./foo?dir=bar";         expected = FAIL; };
    fail3 = { expr = ".?dir=bar";             expected = FAIL; };
    fail4 = { expr = "/foo";                  expected = FAIL; };
    fail5 = { expr = "/foo/bar";              expected = FAIL; };
    fail6 = { expr = "/foo/bar/baz";          expected = FAIL; };
    fail7 = { expr = "/foo/bar/baz?dir=quux"; expected = FAIL; };
    fail8 = { expr = "///foo";                expected = FAIL; };
    # FIXME: detect unsupported parameters
    #fail9 = { expr = "path:/foo/bar/baz?dir=quux"; expected = "path"; };


    file0 = { expr = "https://registry.npmjs.org/lodash"; expected = "file"; };
    file1 = { expr = "http://registry.npmjs.org/lodash";  expected = "file"; };
    file2 = {
      expr     = "file+https://registry.npmjs.org/lodash";
      expected = "file";
    };
    file3 = {
      expr     = "file+http://registry.npmjs.org/lodash";
      expected = "file";
    };
    file4 = {
      expr     = "file+https://registry.npmjs.org/lodash?_rev=xxxxxxx";
      expected = "file";
    };
    file5 = { expr = "file+file:///home/user/.zshrc"; expected = "file"; };
    file6 = { expr = "file:///home/user/.zshrc";      expected = "file"; };


    tarball0 = {
      expr     = "https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz";
      expected = "tarball";
    };
    tarball1 = {
      expr     = "http://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz";
      expected = "tarball";
    };
    tarball2 = {
      expr     = "https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz?x=1";
      expected = "tarball";
    };
    tarball3 = {
      expr     = "file:///home/user/file.tar.gz";
      expected = "tarball";
    };
    tarball4 = {
      expr     = "file:///home/user/file.zip";
      expected = "tarball";
    };
    tarball5 = {
      expr     = "file:///home/user/file.tar";
      expected = "tarball";
    };
    tarball6 = {
      expr     = "file:///home/user/file.tar.bz2";
      expected = "tarball";
    };
    tarball7 = {
      expr     = "file:///home/user/file.tar.xz";
      expected = "tarball";
    };
    tarball8 = {
      expr     = "file:///home/user/file.tar.zst";
      expected = "tarball";
    };
    tarball9 = {
      expr     = "tarball+file:///home/user/file.tgz";
      expected = "tarball";
    };
    tarball10 = {
      expr     = "tarball:///home/user/file.tgz";
      expected = "tarball";
    };
    tarball11 = {
      expr     = "tarball:///home/user/file";
      expected = "tarball";
    };
    tarball12 = {
      expr     = "tarball+file:///home/user/file";
      expected = "tarball";
    };
    tarball13 = {
      expr     = "tarball+file:/home/user/file";
      expected = "tarball";
    };


    git0 = {
      expr     = "git+ssh://git@github.com/flox/flox.git";
      expected = "git";
    };
    git1 = {
      expr     = "git+https://github.com/flox/flox.git";
      expected = "git";
    };
    git2 = {
      expr     = "git+http://github.com/flox/flox.git";
      expected = "git";
    };
    git3 = {
      expr     = "git+ssh://git@github.com/flox/flox.git?ref=main";
      expected = "git";
    };
    git4 = {
      expr = "git+https://github.com/flox/flox.git" +
             "?rev=a3a3dda3bacf61e8a39258a0ed9c924eeca8e293&ref=main";
      expected = "git";
    };
    git5 = {
      expr     = "git+https://github.com/flox/flox/archive/main.tar.gz";
      expected = "git";
    };


    github0 = { expr = "github:flox/flox";      expected = "github"; };
    github1 = { expr = "github:flox/flox/main"; expected = "github"; };
    github2 = {
      expr     = "github:flox/flox/a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
      expected = "github";
    };
    github3 = {
      expr     = "github:flox/flox/refs/heads/main?dir=lib";
      expected = "github";
    };
    github4 = {
      expr     = "github:flox/flox?ref=refs/heads/main&dir=lib";
      expected = "github";
    };


    gitlab0 = { expr = "gitlab:flox/flox";      expected = "gitlab"; };
    gitlab1 = { expr = "gitlab:flox/flox/main"; expected = "gitlab"; };
    gitlab2 = {
      expr     = "gitlab:flox/flox/a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
      expected = "gitlab";
    };
    gitlab3 = {
      expr     = "gitlab:flox/flox/refs/heads/main?dir=lib";
      expected = "gitlab";
    };
    gitlab4 = {
      expr     = "gitlab:flox/flox?ref=refs/heads/main&dir=lib";
      expected = "gitlab";
    };


    sourcehut0 = { expr = "sourcehut:flox/flox";      expected = "sourcehut"; };
    sourcehut1 = { expr = "sourcehut:flox/flox/main"; expected = "sourcehut"; };
    sourcehut2 = {
      expr     = "sourcehut:flox/flox/a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
      expected = "sourcehut";
    };
    sourcehut3 = {
      expr     = "sourcehut:flox/flox/refs/heads/main?dir=lib";
      expected = "sourcehut";
    };
    sourcehut4 = {
      expr     = "sourcehut:flox/flox?ref=refs/heads/main&dir=lib";
      expected = "sourcehut";
    };


    # TODO: mercurial

  };


# ---------------------------------------------------------------------------- #

  flakeRefStrToAttrsTests = let
    apply = _: { expr, ... } @ test: test // {
      expr = flakeRefStrToAttrs expr;
    };
  in builtins.mapAttrs apply {

    indirect0 = {
      expr     = "nixpkgs";
      expected = { id = "nixpkgs"; type = "indirect"; };
    };
    indirect1 = {
      expr     = "nixpkgs/a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
      expected = {
        type = "indirect";
        id   = "nixpkgs";
        rev  = "a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
      };
    };
    indirect2 = {
      expr     = "nixpkgs/REF";
      expected = {
        type = "indirect";
        id   = "nixpkgs";
        ref  = "REF";
      };
    };
    indirect3 = {
      expr = "flake:nixpkgs";
      expected = {
        type = "indirect";
        id   = "nixpkgs";
      };
    };
    indirect4 = {
      expr     = "flake:nixpkgs?dir=lib";
      expected = {
        type = "indirect";
        id   = "nixpkgs";
        dir  = "lib";
      };
    };
    indirect5 = {
      expr     = "flake:nixpkgs/a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
      expected = {
        type = "indirect";
        id   = "nixpkgs";
        rev  = "a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
      };
    };
    indirect6 = {
      expr     = "flake:nixpkgs/REF";
      expected = {
        type = "indirect";
        id   = "nixpkgs";
        ref  = "REF";
      };
    };
    indirect7 = {
      expr     = "flake:nixpkgs/REF?dir=lib";
      expected = {
        type = "indirect";
        id   = "nixpkgs";
        ref  = "REF";
        dir  = "lib";
      };
    };


    path0 = {
      expr     = "path:/foo";
      expected = {
        type = "path";
        path = "/foo";
      };
    };
    path1 = {
      expr = "path:/foo/bar";
      expected = {
        type = "path";
        path = "/foo/bar";
      };
    };
    path2 = {
      expr = "path:/foo/bar/baz";
      expected = {
        type = "path";
        path = "/foo/bar/baz";
      };
    };
    path3 = {
      expr = "path:./foo";
      expected = {
        type = "path";
        path = "./foo";
      };
    };
    path4 = {
      expr = "path:./foo/bar";
      expected = {
        type = "path";
        path = "./foo/bar";
      };
    };
    path5 = {
      expr = "path:./foo/bar/baz";
      expected = {
        type = "path";
        path = "./foo/bar/baz";
      };
    };


    # These LOOK like `path', but are actually invalid.
    fail0 = { expr = "./foo";                 expected = FAIL; };
    fail1 = { expr = ".";                     expected = FAIL; };
    fail2 = { expr = "./foo?dir=bar";         expected = FAIL; };
    fail3 = { expr = ".?dir=bar";             expected = FAIL; };
    fail4 = { expr = "/foo";                  expected = FAIL; };
    fail5 = { expr = "/foo/bar";              expected = FAIL; };
    fail6 = { expr = "/foo/bar/baz";          expected = FAIL; };
    fail7 = { expr = "/foo/bar/baz?dir=quux"; expected = FAIL; };
    fail8 = { expr = "///foo";                expected = FAIL; };
    # FIXME: detect unsupported parameters
    #fail9 = { expr = "path:/foo/bar/baz?dir=quux"; expected = "path"; };


    # TODO: Audit whether the `nix' parser preserves `:///' URLs/paths or
    # shortens them to something else.

    file0 = {
      expr     = "https://registry.npmjs.org/lodash";
      expected = {
        type = "file";
        url  = "https://registry.npmjs.org/lodash";
      };
    };
    file1 = {
      expr     = "http://registry.npmjs.org/lodash";
      expected = {
        type = "file";
        url  = "http://registry.npmjs.org/lodash";
      };
    };
    file2 = {
      expr     = "file+https://registry.npmjs.org/lodash";
      expected = {
        type = "file";
        url  = "https://registry.npmjs.org/lodash";
      };
    };
    file3 = {
      expr     = "file+http://registry.npmjs.org/lodash";
      expected = {
        type = "file";
        url  = "http://registry.npmjs.org/lodash";
      };
    };
    file4 = {
      expr     = "file+https://registry.npmjs.org/lodash?_rev=xxxxxxx";
      expected = {
        type = "file";
        url  = "https://registry.npmjs.org/lodash?_rev=xxxxxxx";
      };
    };
    file5 = {
      expr     = "file+file:///home/user/.zshrc";
      expected = {
        type = "file";
        url  = "file:///home/user/.zshrc";
      };
    };
    file6 = {
      expr     = "file:///home/user/.zshrc";
      expected = {
        type = "file";
        url  = "file:///home/user/.zshrc";
      };
    };


    tarball0 = {
      expr     = "https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz";
      expected = {
        type = "tarball";
        url  = "https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz";
      };
    };
    tarball1 = {
      expr     = "http://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz";
      expected = {
        type = "tarball";
        url  = "http://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz";
      };
    };
    tarball2 = {
      expr     = "https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz?x=1";
      expected = {
        type = "tarball";
        url  = "https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz?x=1";
      };
    };
    tarball3 = {
      expr     = "file:///home/user/file.tar.gz";
      expected = {
        type = "tarball";
        url  = "file:///home/user/file.tar.gz";
      };
    };
    tarball4 = {
      expr     = "file:///home/user/file.zip";
      expected = {
        type = "tarball";
        url  = "file:///home/user/file.zip";
      };
    };
    tarball5 = {
      expr     = "file:///home/user/file.tar";
      expected = {
        type = "tarball";
        url  = "file:///home/user/file.tar";
      };
    };
    tarball6 = {
      expr     = "file:///home/user/file.tar.bz2";
      expected = {
        type = "tarball";
        url  = "file:///home/user/file.tar.bz2";
      };
    };
    tarball7 = {
      expr     = "file:///home/user/file.tar.xz";
      expected = {
        type = "tarball";
        url  = "file:///home/user/file.tar.xz";
      };
    };
    tarball8 = {
      expr     = "file:///home/user/file.tar.zst";
      expected = {
        type = "tarball";
        url  = "file:///home/user/file.tar.zst";
      };
    };
    tarball9 = {
      expr     = "tarball+file:///home/user/file.tgz";
      expected = {
        type = "tarball";
        url  = "file:///home/user/file.tgz";
      };
    };
    tarball10 = {
      expr     = "tarball:///home/user/file.tgz";
      expected = {
        type = "tarball";
        url  = "tarball:///home/user/file.tgz";
      };
    };
    tarball11 = {
      expr     = "tarball:///home/user/file";
      expected = {
        type = "tarball";
        url  = "tarball:///home/user/file";
      };
    };
    tarball12 = {
      expr     = "tarball+file:///home/user/file";
      expected = {
        type = "tarball";
        url  = "file:///home/user/file";
      };
    };
    tarball13 = {
      expr     = "tarball+file:/home/user/file";
      expected = {
        type = "tarball";
        url  = "file:/home/user/file";
      };
    };


    git0 = {
      expr     = "git+ssh://git@github.com/flox/flox.git";
      expected = {
        type = "git";
        url  = "ssh://git@github.com/flox/flox.git";
      };
    };
    git1 = {
      expr     = "git+https://github.com/flox/flox.git";
      expected = {
        type = "git";
        url  = "https://github.com/flox/flox.git";
      };
    };
    git2 = {
      expr     = "git+http://github.com/flox/flox.git";
      expected = {
        type = "git";
        url  = "http://github.com/flox/flox.git";
      };
    };
    git3 = {
      expr     = "git+ssh://git@github.com/flox/flox.git?ref=main";
      expected = {
        type = "git";
        url  = "ssh://git@github.com/flox/flox.git";
        ref  = "main";
      };
    };
    git4 = {
      expr = "git+https://github.com/flox/flox.git" +
             "?rev=a3a3dda3bacf61e8a39258a0ed9c924eeca8e293&ref=main";
      expected = {
        type = "git";
        url  = "https://github.com/flox/flox.git";
        rev  = "a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
        ref  = "main";
      };
    };
    git5 = {
      expr     = "git+https://github.com/flox/flox/archive/main.tar.gz";
      expected = {
        type = "git";
        url  = "https://github.com/flox/flox/archive/main.tar.gz";
      };
    };


    github0 = {
      expr     = "github:flox/flox";
      expected = {
        type  = "github";
        owner = "flox";
        repo  = "flox";
      };
    };
    github1 = {
      expr     = "github:flox/flox/main";
      expected = {
        type  = "github";
        owner = "flox";
        repo  = "flox";
        ref   = "main";
      };
    };
    github2 = {
      expr     = "github:flox/flox/a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
      expected = {
        type  = "github";
        owner = "flox";
        repo  = "flox";
        rev   = "a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
      };
    };
    github3 = {
      expr     = "github:flox/flox/refs/heads/main?dir=lib";
      expected = {
        type  = "github";
        owner = "flox";
        repo  = "flox";
        ref   = "refs/heads/main";
        dir   = "lib";
      };
    };
    github4 = {
      expr     = "github:flox/flox?ref=refs/heads/main&dir=lib";
      expected = {
        type  = "github";
        owner = "flox";
        repo  = "flox";
        ref   = "refs/heads/main";
        dir   = "lib";
      };
    };


    sourcehut0 = {
      expr     = "sourcehut:flox/flox";
      expected = {
        type  = "sourcehut";
        owner = "flox";
        repo  = "flox";
      };
    };
    sourcehut1 = {
      expr     = "sourcehut:flox/flox/main";
      expected = {
        type  = "sourcehut";
        owner = "flox";
        repo  = "flox";
        ref   = "main";
      };
    };
    sourcehut2 = {
      expr     = "sourcehut:flox/flox/a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
      expected = {
        type  = "sourcehut";
        owner = "flox";
        repo  = "flox";
        rev   = "a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
      };
    };
    sourcehut3 = {
      expr     = "sourcehut:flox/flox/refs/heads/main?dir=lib";
      expected = {
        type  = "sourcehut";
        owner = "flox";
        repo  = "flox";
        ref   = "refs/heads/main";
        dir   = "lib";
      };
    };
    sourcehut4 = {
      expr     = "sourcehut:flox/flox?ref=refs/heads/main&dir=lib";
      expected = {
        type  = "sourcehut";
        owner = "flox";
        repo  = "flox";
        ref   = "refs/heads/main";
        dir   = "lib";
      };
    };


    gitlab0 = {
      expr     = "gitlab:flox/flox";
      expected = {
        type  = "gitlab";
        owner = "flox";
        repo  = "flox";
      };
    };
    gitlab1 = {
      expr     = "gitlab:flox/flox/main";
      expected = {
        type  = "gitlab";
        owner = "flox";
        repo  = "flox";
        ref   = "main";
      };
    };
    gitlab2 = {
      expr     = "gitlab:flox/flox/a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
      expected = {
        type  = "gitlab";
        owner = "flox";
        repo  = "flox";
        rev   = "a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
      };
    };
    gitlab3 = {
      expr     = "gitlab:flox/flox/refs/heads/main?dir=lib";
      expected = {
        type  = "gitlab";
        owner = "flox";
        repo  = "flox";
        ref   = "refs/heads/main";
        dir   = "lib";
      };
    };
    gitlab4 = {
      expr     = "gitlab:flox/flox?ref=refs/heads/main&dir=lib";
      expected = {
        type  = "gitlab";
        owner = "flox";
        repo  = "flox";
        ref   = "refs/heads/main";
        dir   = "lib";
      };
    };


    # TODO: mercurial

  };  /* End `flakeRefStrToAttrs' */


# ---------------------------------------------------------------------------- #

  flakeRefAttrsToStrTests = let
    apply = _: { expr, ... } @ test: test // {
      expr = flakeRefAttrsToStr expr;
    };
  in builtins.mapAttrs apply {

    indirect0 = {
      expr     = { id = "nixpkgs"; type = "indirect"; };
      expected = "flake:nixpkgs";
    };
    indirect1 = {
      expr = {
        type = "indirect";
        id   = "nixpkgs";
        rev  = "a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
      };
      expected = "flake:nixpkgs/a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
    };
    indirect2 = {
      expr = {
        type = "indirect";
        id   = "nixpkgs";
        ref  = "REF";
      };
      expected = "flake:nixpkgs/REF";
    };
    indirect3 = {
      expr = {
        type = "indirect";
        id   = "nixpkgs";
        ref  = "REF";
        dir  = "lib";
      };
      expected = "flake:nixpkgs/REF?dir=lib";
    };


    path0 = {
      expr = {
        type = "path";
        path = "/foo";
      };
      expected = "path:/foo";
    };
    path1 = {
      expr = {
        type = "path";
        path = "/foo/bar";
      };
      expected = "path:/foo/bar";
    };
    path2 = {
      expr = {
        type = "path";
        path = "/foo/bar/baz";
      };
      expected = "path:/foo/bar/baz";
    };
    path3 = {
      expr = {
        type = "path";
        path = "./foo";
      };
      expected = "path:./foo";
    };
    path4 = {
      expr = {
        type = "path";
        path = "./foo/bar";
      };
      expected = "path:./foo/bar";
    };
    path5 = {
      expr = {
        type = "path";
        path = "./foo/bar/baz";
      };
      expected = "path:./foo/bar/baz";
    };


    # TODO: Audit whether the `nix' parser preserves `:///' URLs/paths or
    # shortens them to something else.

    file0 = {
      expr = {
        type = "file";
        url  = "https://registry.npmjs.org/lodash";
      };
      expected = "file+https://registry.npmjs.org/lodash";
    };
    file1 = {
      expr = {
        type = "file";
        url  = "http://registry.npmjs.org/lodash";
      };
      expected = "file+http://registry.npmjs.org/lodash";
    };
    file2 = {
      expr = {
        type = "file";
        url  = "https://registry.npmjs.org/lodash";
      };
      expected = "file+https://registry.npmjs.org/lodash";
    };
    file3 = {
      expr = {
        type = "file";
        url  = "http://registry.npmjs.org/lodash";
      };
      expected = "file+http://registry.npmjs.org/lodash";
    };
    file4 = {
      expr = {
        type = "file";
        url  = "https://registry.npmjs.org/lodash?_rev=xxxxxxx";
      };
      expected = "file+https://registry.npmjs.org/lodash?_rev=xxxxxxx";
    };
    file5 = {
      expr = {
        type = "file";
        url  = "file:///home/user/.zshrc";
      };
      expected = "file+file:///home/user/.zshrc";
    };
    file6 = {
      expr = {
        type = "file";
        url  = "file:///home/user/.zshrc";
      };
      expected = "file+file:///home/user/.zshrc";
    };


    tarball0 = {
      expr = {
        type = "tarball";
        url  = "https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz";
      };
      expected =
        "tarball+https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz";
    };
    tarball1 = {
      expr = {
        type = "tarball";
        url  = "http://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz";
      };
      expected =
        "tarball+http://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz";
    };
    tarball2 = {
      expr = {
        type = "tarball";
        url  = "https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz?x=1";
      };
      expected =
        "tarball+https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz?x=1";
    };
    tarball3 = {
      expr = {
        type = "tarball";
        url  = "file:///home/user/file.tar.gz";
      };
      expected = "tarball+file:///home/user/file.tar.gz";
    };
    tarball4 = {
      expr = {
        type = "tarball";
        url  = "file:///home/user/file.zip";
      };
      expected = "tarball+file:///home/user/file.zip";
    };
    tarball5 = {
      expr = {
        type = "tarball";
        url  = "file:///home/user/file.tar";
      };
      expected = "tarball+file:///home/user/file.tar";
    };
    tarball6 = {
      expr = {
        type = "tarball";
        url  = "file:///home/user/file.tar.bz2";
      };
      expected = "tarball+file:///home/user/file.tar.bz2";
    };
    tarball7 = {
      expr = {
        type = "tarball";
        url  = "file:///home/user/file.tar.xz";
      };
      expected = "tarball+file:///home/user/file.tar.xz";
    };
    tarball8 = {
      expr = {
        type = "tarball";
        url  = "file:///home/user/file.tar.zst";
      };
      expected = "tarball+file:///home/user/file.tar.zst";
    };
    tarball9 = {
      expr = {
        type = "tarball";
        url  = "file:///home/user/file.tgz";
      };
      expected = "tarball+file:///home/user/file.tgz";
    };
    tarball10 = {
      expr = {
        type = "tarball";
        url  = "tarball:///home/user/file.tgz";
      };
      expected = "tarball:///home/user/file.tgz";
    };
    tarball11 = {
      expr = {
        type = "tarball";
        url  = "tarball:///home/user/file";
      };
      expected = "tarball:///home/user/file";
    };
    tarball12 = {
      expr = {
        type = "tarball";
        url  = "file:///home/user/file";
      };
      expected = "tarball+file:///home/user/file";
    };
    tarball13 = {
      expr = {
        type = "tarball";
        url  = "file:/home/user/file";
      };
      expected = "tarball+file:/home/user/file";
    };


    git0 = {
      expr = {
        type = "git";
        url  = "ssh://git@github.com/flox/flox.git";
      };
      expected = "git+ssh://git@github.com/flox/flox.git";
    };
    git1 = {
      expr = {
        type = "git";
        url  = "https://github.com/flox/flox.git";
      };
      expected = "git+https://github.com/flox/flox.git";
    };
    git2 = {
      expr = {
        type = "git";
        url  = "http://github.com/flox/flox.git";
      };
      expected = "git+http://github.com/flox/flox.git";
    };
    git3 = {
      expr = {
        type = "git";
        url  = "ssh://git@github.com/flox/flox.git";
        ref  = "main";
      };
      expected = "git+ssh://git@github.com/flox/flox.git/main";
    };

    # TODO: audit this result in `nix'.
    # You drop `?ref=main' and I'm not sure if they do.
    git4 = {
      expr = {
        type = "git";
        url  = "https://github.com/flox/flox.git";
        rev  = "a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
        ref  = "main";
      };
      expected = "git+https://github.com/flox/flox.git" +
                 "/a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
    };
    git5 = {
      expr = {
        type = "git";
        url  = "https://github.com/flox/flox/archive/main.tar.gz";
      };
      expected = "git+https://github.com/flox/flox/archive/main.tar.gz";
    };
    git6 = {
      expr = {
        type = "git";
        url  = "ssh://git@github.com/flox/flox.git";
        ref  = "main";
      };
      expected = "git+ssh://git@github.com/flox/flox.git/main";
    };
    git7 = {
      expr = {
        type = "git";
        url  = "ssh://git@github.com/flox/flox.git";
        ref  = "refs/heads/main";
      };
      expected = "git+ssh://git@github.com/flox/flox.git/refs/heads/main";
    };
    git8 = {
      expr = {
        type = "git";
        url  = "ssh://git@github.com/flox/flox.git?x=1";
        ref  = "refs/heads/main";
      };
      expected = "git+ssh://git@github.com/flox/flox.git/refs/heads/main?x=1";
    };

    # TODO: audit this result in `nix'.
    # You drop `?ref=main' and I'm not sure if they do.
    git9 = {
      expr = {
        type = "git";
        url  = "https://github.com/flox/flox.git";
        rev  = "a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
        ref  = "main";
      };
      expected = "git+https://github.com/flox/flox.git" +
                 "/a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
    };

    # TODO: audit this result in `nix'.
    # You drop `?ref=main' and I'm not sure if they do.
    git10 = {
      expr = {
        type = "git";
        url  = "git://git@github.com/flox/flox.git";
        rev  = "a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
        ref  = "main";
      };
      expected = "git://git@github.com/flox/flox.git" +
                 "/a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
    };


    github0 = {
      expr = {
        type  = "github";
        owner = "flox";
        repo  = "flox";
      };
      expected = "github:flox/flox";
    };
    github1 = {
      expr = {
        type  = "github";
        owner = "flox";
        repo  = "flox";
        ref   = "main";
      };
      expected = "github:flox/flox/main";
    };
    github2 = {
      expr = {
        type  = "github";
        owner = "flox";
        repo  = "flox";
        rev   = "a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
      };
      expected = "github:flox/flox/a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
    };
    github3 = {
      expr = {
        type  = "github";
        owner = "flox";
        repo  = "flox";
        ref   = "refs/heads/main";
        dir   = "lib";
      };
      expected = "github:flox/flox/refs/heads/main?dir=lib";
    };
    github4 = {
      expr = {
        type  = "github";
        owner = "flox";
        repo  = "flox";
        ref   = "refs/heads/main";
        dir   = "lib";
      };
      expected = "github:flox/flox/refs/heads/main?dir=lib";
    };


    sourcehut0 = {
      expr = {
        type  = "sourcehut";
        owner = "flox";
        repo  = "flox";
      };
      expected = "sourcehut:flox/flox";
    };
    sourcehut1 = {
      expr = {
        type  = "sourcehut";
        owner = "flox";
        repo  = "flox";
        ref   = "main";
      };
      expected = "sourcehut:flox/flox/main";
    };
    sourcehut2 = {
      expr = {
        type  = "sourcehut";
        owner = "flox";
        repo  = "flox";
        rev   = "a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
      };
      expected = "sourcehut:flox/flox/a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
    };
    sourcehut3 = {
      expr = {
        type  = "sourcehut";
        owner = "flox";
        repo  = "flox";
        ref   = "refs/heads/main";
        dir   = "lib";
      };
      expected = "sourcehut:flox/flox/refs/heads/main?dir=lib";
    };
    sourcehut4 = {
      expr = {
        type  = "sourcehut";
        owner = "flox";
        repo  = "flox";
        ref   = "refs/heads/main";
        dir   = "lib";
      };
      expected = "sourcehut:flox/flox/refs/heads/main?dir=lib";
    };


    gitlab0 = {
      expr = {
        type  = "gitlab";
        owner = "flox";
        repo  = "flox";
      };
      expected = "gitlab:flox/flox";
    };
    gitlab1 = {
      expr = {
        type  = "gitlab";
        owner = "flox";
        repo  = "flox";
        ref   = "main";
      };
      expected = "gitlab:flox/flox/main";
    };
    gitlab2 = {
      expr = {
        type  = "gitlab";
        owner = "flox";
        repo  = "flox";
        rev   = "a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
      };
      expected = "gitlab:flox/flox/a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";
    };
    gitlab3 = {
      expr = {
        type  = "gitlab";
        owner = "flox";
        repo  = "flox";
        ref   = "refs/heads/main";
        dir   = "lib";
      };
      expected = "gitlab:flox/flox/refs/heads/main?dir=lib";
    };
    gitlab4 = {
      expr = {
        type  = "gitlab";
        owner = "flox";
        repo  = "flox";
        ref   = "refs/heads/main";
        dir   = "lib";
      };
      expected = "gitlab:flox/flox/refs/heads/main?dir=lib";
    };


    # TODO: mercurial

  };  /* End `flakeRefAttrsToStr' */


# ---------------------------------------------------------------------------- #

  # Wrap tests in `tryEval' and generate a good name.
  genTests = parent: let
    genTest = name: test: {
      name  = "test_" + parent + "_" + name;
      value = {
        expr = let
          e = builtins.deepSeq test.expr test.expr;
        in builtins.tryEval e;
        # Only wrap if the existing `expected' isn't formed as the result of
        # a `tryEval' call.
        # This allows us to write `expected' values which expec failure.
        expected =
          if ( builtins.isAttrs test.expected ) &&
             ( ( builtins.attrNames test.expected ) == ["success" "value"] )
          then test.expected
          else { success = true; value = test.expected; };
      };
    };
  in tests: builtins.attrValues ( builtins.mapAttrs genTest tests );

  # Joins all tests into a single attrset.
  tests = let
    sets = builtins.mapAttrs genTests {
      inherit
        paramStrToAttrsTests paramAttrsToStrTests
        identifyURITypeTests
        flakeRefStrToAttrsTests flakeRefAttrsToStrTests
      ;
    };
  in builtins.listToAttrs ( builtins.concatLists ( builtins.attrValues sets ) );


# ---------------------------------------------------------------------------- #

  # Returns a list of failed tests with elements of `{ name, expr, expected }'.
  failures = lib.runTests tests;


# ---------------------------------------------------------------------------- #

in {

  # For interactive usage
  inherit lib tests failures;
  fns = import ../lockFlake.nix;

  # Evaluate tests using `(flox|nix) eval -f'
  check = let
    fs = builtins.toJSON ( map ( x: x.name ) failures );
    msg = ''
      FAIL: The following tests failed:
        ${fs}
      Use `(flox|nix) eval -f <floxpkgs>/lib/checks/lockFlake.nix failures;'
      to investigate mismatched expectations.
    '';
  in if failures == [] then true else throw msg;

  # Evaluate tests as a derivation, ideal for `(flox|nix) flake check' or
  # `(flox|nix) build -f checkDrv'.
  checkDrv = {
    bash   ? ( builtins.getAttr system nixpkgs.legacyPackages ).bash
  , system ? if args ? bash then bash.system else builtins.currentSystem
  } @ args: derivation {
    name = "floxpkgs-lockFlake-checks";
    inherit system;
    builder = bash.outPath + "/bin/bash";
    preferLocal = true;
    # Because this derivaiton has no "real" inputs we have to force rebuilds
    # in an awkward way.
    # In `impure' mode we use `builtins.currentTime' and in `pure' mode we hash
    # this file and the file we're testing.
    # In pure mode we may still attempt substitution but it's a relatively good
    # method of forcing rebuilds.
    forceDirty  = let
      hashes = builtins.hashString "sha256" (
        ( builtins.hashFile "sha256" ./lockFlake.nix  ) +
        ( builtins.hashFile "sha256" ../lockFlake.nix )
      );
    in if builtins ? currentTime then toString builtins.currentTime else hashes;
    pass  = failures == [];
    fails = builtins.concatStringsSep "\n" ( map ( x: x.name ) failures );
    args  = ["-eu" "-o" "pipefail" "-c" ''
      if [[ -n "$pass" ]]; then
        echo 'PASS: lockFlake tests' >&2;
        echo 'PASS' > "$out";
        exit 0;
      else
        echo 'FAIL: lockFlake tests' >&2;
        echo 'failures:'             >&2;
        echo "$fails"                >&2;
        # We exit failure so the resulting store path is only preserved if the
        # user explicitly sets `--keep-failed'.
        echo 'FAIL'   > "$out";
        echo "$fails" > "$out";
        exit 1;
      fi
    ''];
  };

}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
