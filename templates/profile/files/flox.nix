{
  # Provides an extensible `<env>/etc/profile` script.
  packages."github:flox/etc-profiles".profile-base = {};
  # Sets common environment variables such as `PKG_CONFIG_PATH' and `MANPATH'.
  packages."github:flox/etc-profiles".profile-common-paths = {};
  # Sets `PYTHONPATH' if `python3' is detected.
  packages."github:flox/etc-profiles".profile-python3 = {};
  # Sets `NODE_PATH' if `node' is detected.
  packages."github:flox/etc-profiles".profile-node = {};

  # Adding a package's `dev' output makes it visible to `pkg-config'
  ##packages.nixpkgs-flox.sqlite = {
  ##  meta.outputsToInstall = ["bin" "out" "dev"];
  ##};

  shell.hook = ''
    # Source `<env>/etc/profile` if it exists.
    [[ -r "$FLOX_ENV/etc/profile" ]] && . "$FLOX_ENV/etc/profile";
  '';
}
