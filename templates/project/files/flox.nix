{
  # flox environment
  #
  # Look at the examples of configuration bellow.
  # check the documentation:
  #   https://floxdev.com/docs/reference/flox-nix-config
  #
  # To learn basics about flox commands see:
  #   https://floxdev.com/docs/basics
  # 
  # Get help:
  #   https://discourse.floxdev.com
  #
  # Happy hacking!
  #

  # Add packages from `nixpkgs-flox` catalog:
  #
  # packages.nixpkgs-flox.go = {};
  # packages.nixpkgs-flox.nodejs = {}
  #
  # Look for packages with `flox search` command.

  # Set environment variables
  #
  # environmentVariables.LANG = "en_US.UTF-8";

  # Run shell hook when you enter flox environment
  # shell.hook = ''
  #   echo "Welcome to flox environment"
  # '';
}
