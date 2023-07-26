{
  nixConfig.extra-substituters = ["https://cache.floxdev.com"];
  nixConfig.extra-trusted-public-keys = ["flox-store-public-0:8c/B+kjIaQ+BloCmNkRUKwaVPFWkriSAd0JJvuDu4F0="];

  inputs.capacitor.url = "github:flox/capacitor?ref=v0";

  # This is needed for backwards compatibility reasons and due to (possible)
  # bug in Nix, you can not `--override-input` flake input that follows.
  # Ideally we would reuse `flox-floxpkgs/nixpkgs` flake input here
  #
  # We must also consider renaming this flake input name (`nixpkgs`) since
  # `nixpkgs-flox` is not regular nixpkgs. Rather it is a flox catalog, which
  # contains multiple nixpkgs.
  inputs.nixpkgs.url = "github:flox/nixpkgs-flox";
  inputs.nixpkgs.inputs.flox-floxpkgs.follows = "";
  inputs.nixpkgs.inputs.flox.follows = "flox";

  # This is needed for `pkgs/flox/default.nix` to refer to the capacitated
  # recipe.
  inputs.flox.url = "git+ssh://git@github.com/flox/flox?ref=latest";
  inputs.flox.inputs.flox-floxpkgs.follows = "";

  # ===========================================================================
  # This bellow are examples to show case how a there should/could be many more
  # packages
  # ===========================================================================
  inputs.tracelinks.url = "git+ssh://git@github.com/flox/tracelinks?ref=main";
  inputs.tracelinks.inputs.flox-floxpkgs.follows = "";

  inputs.builtfilter.url = "github:flox/builtfilter?ref=builtfilter-rs";
  inputs.builtfilter.inputs.flox-floxpkgs.follows = "";

  inputs.etc-profiles.url = "github:flox/etc-profiles";
  # ===========================================================================

  outputs = args @ {capacitor, ...}: capacitor args (
    {
      self,
      inputs,
      lib,
      ...
    }:
      # re-call yourself with overrides, will not work if using in-memory lockfile
      let hydraOverride = path: follows: (inputs.capacitor.lib.capacitor.callFlake
        (builtins.readFile (self + "/flake.lock"))
        self "" "" "root" { }
        [ {
            path = path;
            follows = follows;
          } ]
        ).hydraJobs;
      in
# Define package set structure
    {
      # Limit the systems to fewer or more than default by ucommenting
      packages = {
        builtfilter = {capacitated, ...}: capacitated.builtfilter.packages.builtfilter-rs;
      };

      config = {
        extraPlugins = [
          (inputs.capacitor.plugins.allLocalResources {})
          (import ./plugins/catalog.nix { inherit self lib; } {})
          (inputs.capacitor.plugins.plugins { dir = ./plugins; })

          (inputs.capacitor.plugins.templates {})
        ];
      };

      # reexport of capacitor
      passthru.capacitor = inputs.capacitor;
      # define default plugins
      passthru.defaultPlugins = [
        (inputs.capacitor.plugins.allLocalResources {})
        (import ./plugins/catalog.nix {inherit self lib;} {})
        (import ./plugins/floxEnvs.nix {inherit self lib;} {
          sourceType="packages";
          dir="pkgs";
        })
        (import ./plugins/rootFloxEnvs.nix {inherit self lib;} {})
      ];

      passthru.project = args: config:
        inputs.capacitor ({ nixpkgs = inputs.nixpkgs; } // args) (
          context:
            lib.recursiveUpdate {
              config.plugins = inputs.capacitor.defaultPlugins ++ self.defaultPlugins;
            }
            (config context)
        );

      passthru."hydraJobsStaging" = hydraOverride ["nixpkgs" "nixpkgs"] ["nixpkgs" "nixpkgs-staging"];
      passthru."hydraJobsUnstable" = hydraOverride ["nixpkgs" "nixpkgs"] ["nixpkgs" "nixpkgs-unstable"];
      passthru."hydraJobsStable" = hydraOverride ["nixpkgs" "nixpkgs"] ["nixpkgs" "nixpkgs-stable"];
    }
  );
}
