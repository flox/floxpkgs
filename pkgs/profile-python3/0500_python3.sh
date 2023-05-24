# ============================================================================ #
#
# Setup Python3
#
# ---------------------------------------------------------------------------- #

# Only run if `python3' is in `PATH'
if command -v python3 >/dev/null; then
  # Get the major/minor version from `python3' to determine the correct path.
  _env_pypath="$FLOX_ENV/lib/python$(
    python3 -c 'import sys
print( "{}.{}".format( sys.version_info[0], sys.version_info[1] ) )';
  )/site-packages";
  # Only add the path if its missing
  case ":${PYTHONPATH:-}:" in
    *:"$_env_pypath":*) :; ;;
    *) PYTHONPATH="${PYTHONPATH:+$PYTHONPATH:}$_env_pypath"; ;;
  esac
  export PYTHONPATH;
fi


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
