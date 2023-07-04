{
  # A few classics.
  packages.nixpkgs-flox.coreutils = {};
  packages.nixpkgs-flox.findutils = {};
  packages.nixpkgs-flox.diffutils = {};
  packages.nixpkgs-flox.gnused    = {};
  packages.nixpkgs-flox.gnugrep   = {};
  packages.nixpkgs-flox.gawk      = {};
  packages.nixpkgs-flox.patch     = {};
  packages.nixpkgs-flox.file      = {};
  packages.nixpkgs-flox.jq        = {};

  # Compression
  packages.nixpkgs-flox.gnutar = {};
  packages.nixpkgs-flox.xz     = {};
  packages.nixpkgs-flox.gzip   = {};
  packages.nixpkgs-flox.bzip2  = {};

  # Scripting
  packages.nixpkgs-flox.bashInteractive = {};
  packages.nixpkgs-flox.nodejs-slim     = {};
  inline.packages.npm                   = { nodejs }: nodejs.pkgs.npm;
  packages.nixpkgs-flox.python3         = {};
  inline.packages.pip                   = { python3 }: python3.pkgs.pip;

  # Fetching and Networking
  packages.nixpkgs-flox.curl    = {};
  packages.nixpkgs-flox.wget    = {};
  packages.nixpkgs-flox.gitFull = {};
  ##packages.nixpkgs-flox.ncat    = {};
  ##packages.nixpkgs-flox.openssh = {};

  # Build Utils
  packages.nixpkgs-flox.gnumake    = {};
  packages.nixpkgs-flox.libtool    = {};
  packages.nixpkgs-flox.autoconf   = {};
  packages.nixpkgs-flox.automake   = {};
  packages.nixpkgs-flox.gnum4      = {};
  packages.nixpkgs-flox.pkg-config = {};

  # Compiler Collection
  # Selects `gcc' on Linux, and LLVM on Darwin.
  inline.packages.cc = { stdenv }: stdenv.cc;

  # Debugging
  ##packages.nixpkgs-flox.gdb      = {};
  ##packages.nixpkgs-flox.valgrind = {};

  # Text Editing
  ##packages.nixpkgs-flox.vimHugeX = {};

  # Interactive Extras
  ##packages.nixpkgs-flox.zsh             = {};
  ##packages.nixpkgs-flox.tmux            = {};
  ##packages.nixpkgs-flox.silver-searcher = {};
  ##packages.nixpkgs-flox.fzf             = {};


  # Provides an extensible `<env>/etc/profile` script.
  packages."github:flox/etc-profiles".etc-profiles = {
    outputsToInstall = [
      # Provides a simple `<env>/etc/profile' script that sources
      # "child" `<env>/etc/profile.d/*.sh' scripts.
      "out"
      # Sets common environment vars such as `PKG_CONFIG_PATH' and `MANPATH'.
      "common_paths"
      # Sets `PYTHONPATH' if `python3' is detected.
      "python3"
      # Sets `NODE_PATH' if `node' is detected.
      "node"
    ];
  };

  # Grab some development dependencies.
  # Adding a package's `dev' output makes it visible to `pkg-config'.
  # Conventionally `dev' outputs will carry `include/' and `lib/pkgconfig/'
  # paths required for hacking around.
  ##packages.nixpkgs-flox.sqlite = {
  ##  meta.outputsToInstall = ["bin" "out" "dev"];
  ##};

  shell.hook = ''
    # Source `<env>/etc/profile` if it exists.
    [[ -r "$FLOX_ENV/etc/profile" ]] && . "$FLOX_ENV/etc/profile";
  '';
}
