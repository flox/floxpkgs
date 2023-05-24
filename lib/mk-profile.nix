# ============================================================================ #
#
# Creates a `<env>/etc/profile.d/*.sh' script as an installable.
#
# ---------------------------------------------------------------------------- #

let
  prioToPrefix = p: let
    pi  = if builtins.isString p then builtins.fromJSON p else p;
    ps  = if builtins.isString p then p else toString p;
  in if p == null then "" else
     if pi < 1000 then "000" + ps + "_" else
     if pi < 100  then "00"  + ps + "_" else
     if pi < 10   then "0"   + ps + "_" else
     ps + "_";
  npp = p: let
    m = builtins.match "profile-(.*)" p;
  in if m == null then p else builtins.head m;
in
{ bash, coreutils, system }:
{ script
, pname
, version         ? "0.1.0"
, priority        ? null                   # Integer 0-9999 or `null'
, sname           ? ( prioToPrefix priority ) + ( npp pname )
, description     ? "An `/etc/profile.d/*.sh` script managing ${npp pname}."
, longDescription ? description
, platforms       ? [
    "x86_64-linux"  "aarch64-linux"  "i686-linux"
    "x86_64-darwin" "aarch64-darwin"
  ]
}: ( derivation {
  inherit system pname version script sname;
  name    = pname + "-" + version;
  builder = bash.outPath + "/bin/bash";
  PATH    = coreutils.outPath + "/bin";
  args    = let
    profile_d = builtins.path { path = ./profile.d; };
  in ["-eu" "-o" "pipefail" "-c" ''
    mkdir -p "$out/etc/profile.d";
    cp -- "$script" "$out/etc/profile.d/$sname";
  ''];
  preferLocalBuild = true;
  allowSubstitutes = system == ( builtins.currentSystem or null );
} ) // {
  meta = {
    inherit description longDescription platforms;
    outputsToInstall = ["out"];
    homepage         = "https://github.com/flox/floxpkgs";
    license          = {
      fullName        = "MIT License";
      shortName       = "mit";
      spdxId          = "MIT";
      url             = "https://spdx.org/licenses/MIT.html";
      deprecated      = false;
      free            = true;
      redistributable = true;
    };
    maintainers = [];
  };
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
