# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

let

# ---------------------------------------------------------------------------- #

  splitSname = script: let
    sname = baseNameOf script;
    m     = builtins.match "([^_]*)_(.*).sh" sname;
    bname = builtins.elemAt m 1;
  in {
    inherit sname bname;
    priority = builtins.head m;
    pname    = "profile-" + bname;
  };


# ---------------------------------------------------------------------------- #

  mkEtcProfile = { bash, coreutils, system }: import ./mk-profile.nix {
    inherit bash coreutils system;
  };

  mkProfileLocal = {
    lib
  , bash
  , coreutils
  , system
  , script
  , description     ? null
  , longDescription ? null
  , ...
  } @ args: let
    ss = splitSname script;
  in {
    name  = ss.bname;
    value = lib.makeOverridable mkEtcProfile (
      ( removeAttrs ss ["bname" "bash" "coreutils" "system" "lib"] ) // args
    );
  };




# ---------------------------------------------------------------------------- #

in {

  inherit mkEtcProfile mkProfileLocal;

}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
