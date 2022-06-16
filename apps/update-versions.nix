{
  writeShellApplication,
  nix-editor,
  alejandra,
  dasel,
  jq,
  ...
}: {
  type = "app";
  program =
    (writeShellApplication {
      name = "update-versions";
      runtimeInputs = [nix-editor alejandra dasel jq];
      text = ''
        wd="$1"
        cd "$wd"
        if [ -v DEBUG ]; then set -x; fi
        # System should not matter here
        raw_versions=$(
        dasel -f flox.toml -w json | jq '
          .floxEnv.programs|
          to_entries|
          map(select(.value|has("version")))|
          .[]|
          [.key,.value.version]|@tsv
        ' -cr)
        if [ ! -v DRY_RUN ]; then
          nix-editor flake.nix "outputs.__pins.versions" -v "[]" -o flake.nix
        else
          echo "$raw_versions"
          echo "dry run" >&2
          exit 0
        fi

        if [ -z "$raw_versions" ]; then
          echo no versions >&2
          exit 0
        fi

        # TODO: do resolution in parallel
        while read -r line; do
            # shellcheck disable=SC2086
            res=$(AS_FLAKEREF=1 flox run floxpkgs#find-version $line)
            echo "adding $line as $res to $PWD/flake.nix"
            # shellcheck disable=SC2086
            if [ ! -v DRY_RUN ]; then
              nix-editor flake.nix "outputs.__pins.versions" -a "(builtins.getFlake \"''${res%%\#*}\").''${res##*#} " -o flake.nix
            fi
        done < <(echo "$raw_versions")
        alejandra -q flake.nix
      '';
    })
    + "/bin/update-versions";
}
