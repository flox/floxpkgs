{
  devshell,
  data,
  pkgs,
  lib,
  floxpkgs,
  pins,
  ...
}: let
  calledFloxEnv = data.func data.attrs;
  finalPaths = [calledFloxEnv] ++ pins.versions;
in
  (devshell.legacyPackages.${pkgs.system}.mkNakedShell rec {
    name = "ops-env";
    profile = pkgs.buildEnv {
      name = "wrapper";
      paths = finalPaths;

      postBuild = let
        versioned =
          builtins.filter (x: builtins.isString x && !builtins.hasContext x)
          calledFloxEnv.passthru.paths;
        split = map (x: builtins.concatStringsSep " " (lib.strings.splitString "@" x)) versioned;
        /*
         ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo $HOME/.config/flox/ )
         if compgen -G "$ROOT/.flox-${name}"* >/dev/null; then
           rm "$ROOT/.flox-${name}"*
         fi
         ${builtins.concatStringsSep "\n" (map (
             x: ''
               echo Searching: "${x}"
               ref=$( AS_FLAKEREF=1 ${floxpkgs.apps.${pkgs.system}.find-version.program} ${x})
               echo Installing: "$ref"
               flox profile install --profile "$ROOT/.flox-${name}" $ref
             ''
           )
           split)}
         flox profile wipe-history --profile "$ROOT/.flox-${name}" >/dev/null 2>/dev/null
         */
        envBash = pkgs.writeTextDir "env.bash" ''
          export PATH="@DEVSHELL_DIR@/bin:$PATH"
          ${data.attrs.postShellHook or ""}

        '';
      in "substitute ${envBash}/env.bash $out/env.bash --subst-var-by DEVSHELL_DIR $out";
    };
  })
  // {
    passthru.paths =
      builtins.filter (x: !(builtins.isString x && !builtins.hasContext x))
      (calledFloxEnv.passthru.paths ++ pins.versions);
    passthru.pure-paths =
      let paths = builtins.filter (x: !(builtins.isString x && !builtins.hasContext x))
                  (calledFloxEnv.passthru.paths);
      in
      map  (drv:
        {
          storePaths = lib.attrValues (lib.genAttrs drv.outputs (output: builtins.unsafeDiscardStringContext drv.${output}.outPath));
        } // (if drv?attribute_path
        then {
          active = true;
          attrPath = builtins.concatStringsSep "." ([pkgs.system] ++ drv.attribute_path);
          originalUrl = null;
          url = null;
        }
        else {}
        ))
        paths;
    passthru.programs = calledFloxEnv.passthru.programs;
    passthru.data = data;
    passthru.pins = pins;
    passthru.python = calledFloxEnv.passthru.python;
  }
