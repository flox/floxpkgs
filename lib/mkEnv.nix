# Capacitor API
{
  lib,
  self,
}: args @ {
  name ? "floxShell",
  # A path to a buildEnv that will be loaded by the shell.
  # We assume that the buildEnv contains an ./activate script.
  packages ? [],
  meta ? {},
  passthru ? {},
  env ? {},
  aliases ? {},
  manifestPath ? null,
  pkgs,
  attrPath ? [],
  context ? null,
  ...
}:
# TODO: let packages' = if builtins.isList builtins.isSet
let
  bashPath = "${bashInteractive}/bin/bash";
  stdenv = writeTextFile {
    name = "naked-stdenv";
    destination = "/setup";
    text = ''
      # Fix for `nix develop`
      : ''${outputs:=out}
      runHook() {
        eval "$shellHook"
        unset runHook
      }
    '';
  };
  inherit
    (pkgs)
    buildEnv
    writeTextDir
    system
    coreutils
    bashInteractive
    writeTextFile
    ;
  rest = builtins.removeAttrs args [
    "name"
    "profile"
    "packages"
    "meta"
    "passthru"
    "env"
    "aliases"
    "manifestPath"
    "pkgs"
    "postShellHook"
    "context"
    "attrPath"
  ];
  envToBash = name: value: "export ${name}=${lib.escapeShellArg (toString value)}";

  stringAliases = builtins.concatStringsSep "\n" (
    lib.mapAttrsFlatten (k: v: "alias ${k}=${lib.escapeShellArg v}")
    (lib.filterAttrs (k: v: v != null) aliases)
  );

  exportedEnvVars = let
    allValuesLists =
      lib.mapAttrs (n: lib.toList) args.env;
    exportVariables =
      lib.mapAttrsToList (n: v: ''export ${n}=${lib.escapeShellArg (lib.concatStringsSep ":" v)}'') allValuesLists;
  in
    builtins.concatStringsSep "\n" exportVariables;

  envBash = writeTextDir "activate" ''
    export PATH="@DEVSHELL_DIR@/bin:$PATH"

    ${stringAliases}

    ${exportedEnvVars}

    ${args.postShellHook or ""}

    # TODO: assumes git and subflakes will require a correction
    projectRoot="$(git rev-parse --show-toplevel || true)"

    # Ensure we are in the project directory in question
    if [ -n "$projectRoot" ] && [ "${context.self.outPath or ""}" == "$(nix --no-warn-dirty eval .#__reflect.context.self.outPath --raw 2>/dev/null )" ]; then
      mkdir -p "$projectRoot/.flox"

      # Create symlink with gc and generations in .flox/
      rm -f "$projectRoot"/.flox/default* || true
      nix --no-warn-dirty build @DEVSHELL_DIR@ --profile "$projectRoot/.flox/default"
      # Create mutable path
      export PATH="$projectRoot/.flox/default/bin:$PATH"

      # behind a flag due to PATH ordering issues
      if [ -n "$FLOX_LAYERED" ]; then
        exec flox develop ".#packages.${builtins.concatStringsSep "." attrPath}"
      fi
    fi
  '';
  profile = let
    env = derivation {
      name = "profile";
      builder = "builtin:buildenv";
      inherit system;
      manifest = "/dummy";
      derivations = map (x: ["true" (x.meta.priority or 5) 1 x]) args.packages;
    };
    manifestJSON = builtins.toJSON {
      elements =
        map (
          v:
            if v ? meta.element.element
            then let
              el = v.meta.element.element;
            in
              el
              // {
                active = true;
                attrPath = builtins.concatStringsSep "." el.attrPath;
                priority = v.meta.priority or 5;
              }
            else {
              active = true;
              storePaths = [(builtins.unsafeDiscardStringContext v)];
            }
        )
        args.packages;
      version = 2;
    };
    manifestFile = builtins.toFile "profile" manifestJSON;
    manifest = derivation {
      name = "profile";
      inherit system;
      builder = "/bin/sh";
      args = [
        "-c"
        "echo ${env}; ${coreutils}/bin/mkdir $out; ${coreutils}/bin/cp ${
          if manifestPath == null
          then manifestFile
          else manifestPath
        } $out/manifest.json"
      ];
    };
  in
    buildEnv ({
        name = "wrapper";
        paths = args.packages ++ [manifest envBash];

        postBuild = ''
          rm $out/activate ; substitute ${envBash}/activate $out/activate --subst-var-by DEVSHELL_DIR $out
          ${args.postBuild or ""}
        '';
      }
      // (builtins.removeAttrs rest ["postShellHook" "shellHook" "preShellHook" "postBuild"]));
in
  (derivation ({
      inherit name system;
      outputs = ["out"];

      # `nix develop` actually checks and uses builder. And it must be bash.
      builder = bashPath;

      # Bring in the dependencies on `nix-build`
      args = ["-ec" "${coreutils}/bin/ln -s ${profile} $out; exit 0"];

      # $stdenv/setup is loaded by nix-shell during startup.
      # https://github.com/nixos/nix/blob/377345e26f1ac4bbc87bb21debcc52a1d03230aa/src/nix-build/nix-build.cc#L429-L432
      stdenv = stdenv;

      # The shellHook is loaded directly by `nix develop`. But nix-shell
      # requires that other trampoline.
      shellHook = ''
        # Remove all the unnecessary noise that is set by the build env
        unset NIX_BUILD_TOP NIX_BUILD_CORES NIX_STORE
        unset TEMP TEMPDIR TMP TMPDIR
        # $name variable is preserved to keep it compatible with pure shell https://github.com/sindresorhus/pure/blob/47c0c881f0e7cfdb5eaccd335f52ad17b897c060/pure.zsh#L235
        unset builder out shellHook stdenv system
        # Flakes stuff
        unset dontAddDisableDepTrack outputs
        # For `nix develop`. We get /noshell on Linux and /sbin/nologin on macOS.
        if [[ "$SHELL" == "/noshell" || "$SHELL" == "/sbin/nologin" ]]; then
          export SHELL=${bashPath}
        fi
        # Load the environment
        if [ -f "${profile}/activate" ]; then
          source "${profile}/activate"
        fi
      '';
    }
    // rest
    // (args.env or {})))
  // {
    inherit meta passthru;
    packages = builtins.listToAttrs (builtins.map (p: {
      # Seems like the catalog has some "null" names
      name = let
        n = p.pname or p.name or "unamed";
      in
        if n == null
        then "unamed"
        else n;
      value = p;
    }) (args.packages or []));
  }
  // passthru
