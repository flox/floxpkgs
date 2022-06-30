{
  writeShellApplication,
  inputs,
  alejandra,
  dasel,
  jq,
  ...
}: {
  type = "app";
  program =
    (writeShellApplication {
      name = "update-extensions";
      runtimeInputs = [inputs.nix-editor.packages.nixeditor alejandra dasel jq];
      text = ''
        wd="$1"
        cd "$wd"
        if [ -v DEBUG ]; then set -x; fi
        raw_extensions=$(
          dasel -f flox.toml -w json | jq '
          .programs.vscode.extensions|
          select(.!=null)|
          .[]
        ' -cr)
        if [ -z "$raw_extensions" ]; then
          echo no extensions >&2
          if [ ! -v DRY_RUN ]; then
            nix-editor flake.nix "outputs.passthru.__pins.vscode-extensions" -v "[]" -o flake.nix
          fi
          exit 0
        fi

        res=$({
        echo "'''"
        # shellcheck disable=SC2086
        ${./generate_extensions.sh} $raw_extensions | jq -sc .[]
        echo "'''"
        } | flox eval --file - --apply builtins.fromJSON)

        # Reset pins
        if [ ! -v DRY_RUN ]; then
          nix-editor flake.nix "outputs.passthru.__pins.vscode-extensions" -v "[]" -o flake.nix
        fi
        while read -r line; do
        # TODO: detect if in the correct dir
        echo "storing into '$PWD/flake.nix':"
        echo "$line"
        if [ ! -v DRY_RUN ]; then
          nix-editor flake.nix "outputs.passthru.__pins.vscode-extensions" -a "$line" -o flake.nix
          alejandra -q flake.nix
        else
          echo "dry run" >&2
        fi
        done < <(echo "$res")
      '';
    })
    + "/bin/update-extensions";
}
