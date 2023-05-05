# ============================================================================ #
#
# Creates a starter `<env>/etc' directory with profile scripts.
#
# ---------------------------------------------------------------------------- #

{ bash, coreutils, system }: let
  pname   = "flox-base-profile";
  version = "0.1.0";
in ( derivation {
  inherit system pname version;
  name    = pname + "-" + version;
  builder = "${bash}/bin/bash";
  PATH    = "${coreutils}/bin";
  args    = let
    profile_d = builtins.path { path = ./profile.d; };
  in ["-eu" "-o" "pipefail" "-c" ''
    mkdir -p "$out/etc";
    cp -r -- ${profile_d} "$out/etc/profile.d";
    cp    -- ${./profile} "$out/etc/profile";
  ''];
  preferLocalBuild = true;
  allowSubstitutes = system == ( builtins.currentSystem or null );
} ) // {
  meta.description =
   "Creates a starter `<env>/etc' directory with profile scripts";
  meta.longDescription = ''
    Creates a starter `<env>/etc' directory with profile scripts.

    Users can define and install additional scripts in `<env>/etc/profile.d'
    as "custom packages"/installables to share common setup processes
    across environments.

    Recommended usage:
      # flox.nix
      {
        packages.nixpkgs-flox.sqlite = {
          meta.outputsToInstall = ["bin" "out" "dev"];
        };
        packages.nixpkgs-flox.pkg-config = {};
        # Provides `<env>/etc/profile' and `<env>/etc/profile.d/'
        packages.floxpkgs.flox-etc = {};

        shell.hook = '${""}'
          [[ -r "$FLOX_ENV/etc/profile" ]] && . "$FLOX_ENV/etc/profile";
          pkg-config --list-all >&2;
        '${""}'
      }
  '';
  meta.outputsToInstall = ["out"];
  meta.platforms        = [
    "x86_64-linux"  "aarch64-linux"  "i686-linux"
    "x86_64-darwin" "aarch64-darwin"
  ];
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
