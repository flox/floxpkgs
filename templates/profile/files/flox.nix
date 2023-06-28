{
  # A few classics.
  packages.nixpkgs-flox.coreutils       = {};
  packages.nixpkgs-flox.findutils       = {};
  packages.nixpkgs-flox.diffutils       = {};
  packages.nixpkgs-flox.gnused          = {};
  packages.nixpkgs-flox.gnugrep         = {};
  packages.nixpkgs-flox.gawk            = {};
  packages.nixpkgs-flox.gnutar          = {};
  packages.nixpkgs-flox.gzip            = {};
  packages.nixpkgs-flox.bzip2           = {};
  packages.nixpkgs-flox.gnumake         = {};
  packages.nixpkgs-flox.bashInteractive = {};
  packages.nixpkgs-flox.patch           = {};
  packages.nixpkgs-flox.xz              = {};
  packages.nixpkgs-flox.file            = {};
  packages.nixpkgs-flox.jq              = {};
  packages.nixpkgs-flox.python3         = {};
  packages.nixpkgs-flox.nodejs          = {};
  packages.nixpkgs-flox.libtool         = {};
  packages.nixpkgs-flox.autoconf        = {};
  packages.nixpkgs-flox.automake        = {};
  packages.nixpkgs-flox.gnum4           = {};
  packages.nixpkgs-flox.curl            = {};
  packages.nixpkgs-flox.wget            = {};
  packages.nixpkgs-flox.gitFull         = {};
  packages.nixpkgs-flox.vimHugeX        = {};

  # Get `gcc' on Linux, and LLVM on Darwin
  inline.packages.cc = { stdenv }: stdenv.cc;

  packages."github:flox/etc-profiles".etc-profiles = {
    meta.outputsToInstall = [
      # Provides an extensible `<env>/etc/profile` script.
      "base"
      # Sets common environment vars such as `PKG_CONFIG_PATH' and `MANPATH'.
      "common"
      # Sets `PYTHONPATH' if `python3' is detected.
      "python3"
      # Sets `NODE_PATH' if `node' is detected.
      "node"
    ];
  };

  # Adding a package's `dev' output makes it visible to `pkg-config'
  ##packages.nixpkgs-flox.sqlite = {
  ##  meta.outputsToInstall = ["bin" "out" "dev"];
  ##};

  shell.hook = ''
    # If `EDITOR' is undefined, use `vim'.
    : "''${EDITOR:=vim}";
    # Source `<env>/etc/profile` if it exists.
    [[ -r "$FLOX_ENV/etc/profile" ]] && . "$FLOX_ENV/etc/profile";
  '';
}
