# Capacitor API
{
 lib,
 self,
 buildEnv,
 writeTextDir,
 system,
 coreutils,
 bashInteractive,
 writeTextFile,
}:
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
in
args@{ name ? "floxShell"
  # A path to a buildEnv that will be loaded by the shell.
  # We assume that the buildEnv contains an ./env.bash script.
, packages ? [ ]
, meta ? { }
, passthru ? { }
, env ? {}
, ...
}:
# TODO: let packages' = if builtins.isList builtins.isSet
let rest = builtins.removeAttrs args [
  "name"
  "profile"
  "packages"
  "meta"
  "passthru"
  "env"
];
  envToBash = name: value: "export ${name}=${lib.escapeShellArg (toString value)}";
  envBash = writeTextDir "env.bash" ''
    export PATH="@DEVSHELL_DIR@/bin:$PATH"
    ${builtins.concatStringsSep "\n" (builtins.attrValues (builtins.mapAttrs envToBash args.env ))}
    ${args.postShellHook or ""}
  '';
  profile =
     let
       env = derivation {
          name = "profile";
          builder = "builtin:buildenv";
          inherit system;
          manifest = "/dummy";
          derivations = map (x: ["true" 5 1 x]) args.packages;
        };
        manifestJSON  = builtins.toJSON {
          elements = map (v: v.element or (builtins.debugger "")) args.packages;
          version= 2;
        };
       manifestFile = builtins.toFile "profile" manifestJSON;
       manifest = derivation {
          name = "profile";
          inherit system;
          builder = "/bin/sh";
          args = ["-c" "echo ${env}; ${coreutils}/bin/mkdir $out; ${coreutils}/bin/cp ${manifestFile} $out/manifest.json"];
        };
    in
        buildEnv {
          name = "wrapper";
          paths = args.packages ++ [manifest envBash];

          postBuild = "rm $out/env.bash ; substitute ${envBash}/env.bash $out/env.bash --subst-var-by DEVSHELL_DIR $out";
        };
in
(derivation ({
  inherit name system;
  outputs = [ "out" ];

  # `nix develop` actually checks and uses builder. And it must be bash.
  builder = bashPath;

  # Bring in the dependencies on `nix-build`
  args = [ "-ec" "${coreutils}/bin/ln -s ${profile} $out; exit 0" ];

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
    # using nix develop on OSX does not use /noshell
    # https://github.com/numtide/devshell/blob/5a93060a2b3a3d98acfea0596109cb9ac9c04fa7/nix/mkNakedShell.nix#L54
    if [[ "$SHELL" == "/sbin/nologin" ]]; then
      export SHELL=${bashPath}
    fi
    # Load the environment
    source "${profile}/env.bash"
  '';
} // rest // args.env )) // { inherit meta passthru; } // passthru
