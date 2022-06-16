{ pkgs ? (builtins.getFlake "nixpkgs").legacyPackages.x86_64-linux, pulls, ... }:

let

  prs = builtins.fromJSON (builtins.readFile pulls);
  prJobsets =  pkgs.lib.mapAttrs' (num: info: {
    name = "stable-PR-${num}";
    value = {
      enabled = 1;
      hidden = true;
      description = "PR ${num}: ${info.title}";
      checkinterval = 120;
      schedulingshares = 20;
      enableemail = false;
      emailoverride = "";
      keepnr = 1;
      type = 1;
      flake = "git+ssh://git@github.com/flox/floxpkgs?ref=${info.head.ref}";
      flakeattr = "hydraJobsStable";
    };
  }
  ) prs;
  mkFlakeJobset = branch: stability: {
    description = "Packages built with nixpkgs ${pkgs.lib.toLower stability}";
    checkinterval = "600";
    enabled = "1";
    schedulingshares = 100;
    enableemail = false;
    emailoverride = "";
    keepnr = 3;
    hidden = false;
    type = 1;
    flake = "git+ssh://git@github.com/flox/floxpkgs?ref=${branch}";
    flakeattr = "hydraJobs${stability}";
  };

  desc = prJobsets // {
    "stable" = mkFlakeJobset "master" "Stable";
    "staging" = mkFlakeJobset "master" "Staging";
    "unstable" = mkFlakeJobset "master" "Unstable";
  };

  log = {
    pulls = prs;
    jobsets = desc;
  };

in {
  jobsets = pkgs.runCommand "spec-jobsets.json" {} ''
    cat >$out <<EOF
    ${builtins.toJSON desc}
    EOF
    # This is to get nice .jobsets build logs on Hydra
    cat >tmp <<EOF
    ${builtins.toJSON log}
    EOF
    ${pkgs.jq}/bin/jq . tmp
  '';
}

