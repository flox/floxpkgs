# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

# ---------------------------------------------------------------------------- #

  inherit (import ../lockFlake.nix)
    paramStrToAttrs attrsToParamStr
    identifyURIType
    flakeRefStrToAttrs flakeRefAttrsToStr
    lockFlake
  ;


# ---------------------------------------------------------------------------- #

  data = lib.importJSON ./lockFlakeData.json;


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

    emptyQM = {
      expr     = paramAttrsToStr {};
      expected = "?";
    };

    noValue = {
      expr     = paramAttrsToStr { x = null; y = null; z = null; };
      expected = "x&y&z";
    };

    # Ensure that a spurious "?" prefix is ignored.
    qmPrefix = {
      expr     = paramAttrsToStr { x = null; y = null; z = null; };
      expected = "?x&y&z";
    };

    # Ensure that a spurious "&" suffix is ignored.
    andSuffix = {
      expr     = paramAttrsToStr { x = null; y = null; z = null; };
      expected = "x&y&z&";
    };

    values = {
      expr     = paramAttrsToStr { x = "1"; y = "2"; z = "3"; };
      expected = "x=1&y=2&z=3";
    };

    mixed = {
      expr     = paramAttrsToStr { x = "1"; y = null; z = "3"; };
      expected = "x=1&y&z=3";
    };

  };  /* End `paramStrToAttrsTests' */


# ---------------------------------------------------------------------------- #

  # Wrap tests in `tryEval' and generate a good name.
  genTests = parent: let
    genTest = name: test: {
      name  = "test_" + parent + "_" + name;
      value = {
        expr = let
          e = builtins.deepSeq test.expr test.expr;
        in builtins.tryEval e;
        expected =
          if ( builtins.attrNames test.expected ) == ["success" "value"]
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

  # Evaluate tests as a derivation, ideal for `(flox|nix) flake check'.
  checkDrv = {
    bash   ? /bin/sh
  , system ? bash.system or builtins.currentSystem
  }: derivation {
    name = "floxpkgs-lockFlake-checks";
    inherit system;
    builder = if ( bash.type or null ) != "derivation" then bash else
              bash.outPath + "/bin/bash";
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
