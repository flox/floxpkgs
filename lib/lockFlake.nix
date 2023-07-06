# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ inputs }: let

# ---------------------------------------------------------------------------- #

  inherit (inputs.rime.lib) liburi;


# ---------------------------------------------------------------------------- #

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


# ---------------------------------------------------------------------------- #

in lockFlake


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
