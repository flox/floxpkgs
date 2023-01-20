{
  description = "A flox project";

  inputs.flox-floxpkgs.url = "github:flox/floxpkgs";

  outputs = args @ {flox-floxpkgs, ...}:
    flox-floxpkgs.project args (_: {
      config.nixpkgs-config = {
        allowUnfree = false;
        allowedUnfreePackages = [];
      };
    });
}
