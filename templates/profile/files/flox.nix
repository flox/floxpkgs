{
  # Provides an extensible `<env>/etc/profile` script.
  packages."github:flox/etc-profiles".etc-profiles = {
    meta.outputsToInstall = ["base" "common" "python3" "node"];
  };

  # Adding a package's `dev' output makes it visible to `pkg-config'
  ##packages.nixpkgs-flox.sqlite = {
  ##  meta.outputsToInstall = ["bin" "out" "dev"];
  ##};

  shell.hook = ''
    # Source `<env>/etc/profile` if it exists.
    [[ -r "$FLOX_ENV/etc/profile" ]] && . "$FLOX_ENV/etc/profile";
  '';
}
