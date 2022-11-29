set -euo pipefail
if [ "$#" -lt 5 ]; then
    echo "usage: podman-runner <flake path> <check> <ssh key path> <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY> [--override-input inputPath flakeURL]"
    exit 1
fi

flake_path="$1"
shift
check="$1"
shift
ssh_key="$1"
shift
export AWS_ACCESS_KEY_ID="$1"
shift
export AWS_SECRET_ACCESS_KEY="$1"
shift

# Now that we've grabbed AWS creds
set -x

dst_test_dir=/test
dst_overrides_dir="$dst_test_dir/overrides"
dst_container_main="$dst_test_dir/main.sh"
dst_flake_path="$dst_test_dir/flake"
dst_ssh_key="$dst_test_dir/ssh_key"

floxArgs=()
mounts=()
processOverride() {
    inputPath="$1"
    shift
    flakeURL="$1"
    shift

    floxArgs+=("--override-input" "$inputPath")

    # if URL is a path, we'll bind mount it into the container
    if [[ $flakeURL == .* || $flakeURL == /* ]]; then
        # replace / with _
        dst_override_path="$dst_overrides_dir/${inputPath//\//_}"
        mounts+=("--mount=type=bind,src=$flakeURL,dst=$dst_override_path,readonly")
        floxArgs+=("$dst_override_path")
    else
        floxArgs+=("$flakeURL")
    fi
}

while test $# -gt 0; do
    case "$1" in
    --override-input) # takes two args
        shift
        inputPath="$1"
        shift
        flakeURL="$1"
        shift
        processOverride "$inputPath" "$flakeURL"
        ;;
    *)
        echo "Unsupported arg $1"
        exit 1
        ;;
    esac
done

floxEnvVars=()
for var in $(bash -c "compgen -v FLOX_TEST_"); do
    floxEnvVars+=("--env" "$var")
done

podman pull ghcr.io/flox/flox
# we could replace all the podman commands with a single podman run, but this way allows debugging
# and attaching by commenting the trap
container=$(
    podman create -ti --entrypoint "/root/.nix-profile/bin/bash" \
        --env AWS_ACCESS_KEY_ID \
        --env AWS_SECRET_ACCESS_KEY \
        "${floxEnvVars[@]}" \
        "${mounts[@]}" \
        --mount=type=bind,src="$flake_path",dst="$dst_flake_path",readonly \
        --mount=type=bind,src="$ssh_key",dst="$dst_ssh_key",readonly \
        "--mount=type=bind,src=@container_main@,dst=$dst_container_main,readonly" \
        ghcr.io/flox/flox
)

teardown() {
    podman stop "$container"
    podman rm "$container"
}
trap teardown ERR

if ! podman start "$container"; then
    # podman:
    # Error: statfs /nix/store/XXX-container-main.sh: no such file or directory
    # docker:
    # Error response from daemon: invalid mount config for type "bind": bind source path does not exist
    echo "Couldn't start container. If you got an error about /nix/store/... not existing, try re-creating your podman VM with: podman machine init -v /nix:/nix -v $HOME:$HOME"
    exit 1
fi
podman exec "$container" "$dst_container_main" "$dst_flake_path" "$check" "$dst_ssh_key" "${floxArgs[*]}"

echo "Test passed!"

teardown
