{writeShellApplication, curl, coreutils, parallel, gnused, jq, name ? "find-version"}:
{
  type = "app";
  program = (writeShellApplication {
    inherit name;
    runtimeInputs = [ curl jq coreutils parallel gnused ];
    text = ''
attr="$1"

# TODO: detect no version given and provide list, dry-run, show meta

version="$2"
system=''${system:-$(nix show-config | sed -n 's/system = \(.*\)$/\1/p')}

tmpDir="$HOME/.cache/flox/versions"
mkdir -p "$tmpDir"

# Removing for better aarch64 support and more versions
# substituter="''${substituter:-https://beta.floxdev.com}"
# hydra="''${hydra:-https://storehouse.beta.floxdev.com}"
# url="''${url:-github:flox/nixpkgs}"
# project="''${project:-nixpkgs}"
# jobset="''${jobset:-stable}"

substituter="''${substituter:-https://cache.nixos.org}"
hydra="''${hydra:-https://hydra.nixos.org}"
url="''${url:-github:NixOS/nixpkgs}"
project="''${project:-nixpkgs}"
jobsetDefault="trunk"
if [ "$system" == "aarch64-darwin" ]; then
  jobsetDefault="nixpkgs-unstable-aarch64-darwin"
fi
jobset="''${jobset:-$jobsetDefault}"

# assumption is that the cache is availble and configured


export LC_ALL=en_US.UTF-8
# Find all versions built for current system
# shellcheck disable=SC2166
if [ -v REFRESH -o ! -f "$tmpDir/$attr.$system.json" ]; then
    curl -H 'Accept: application/json' "$hydra/job/$project/$jobset/$attr.$system"/closure-sizes -L \
        | jq '.[].id' -cr \
        | parallel --will-cite -n1 curl --silent -H "'Accept: application/json'" "$hydra/build/{}" | jq -cr \
        > "$tmpDir/$attr.$system.json"
fi

if [ -v AS_LIST ]; then
    jq -cr -s --arg version "^$version" '
      map(select(has("timestamp") and .finished == 1))
    | map(select(.nixname|capture("(?<name>.*)-(?<version>[^a-zA-Z].*)")|.version|match($version)!=[]))
    | sort_by(.timestamp)
    | reverse
    | unique_by(.nixname)
    | .[]
    | [(.buildproducts|to_entries[0].value.path),.nixname]
    | @tsv
    ' "$tmpDir/$attr.$system.json"
    exit 0
fi

# Extract name-version from nixname and match the regex provided by user
out=$(jq -cr -s --arg version "^$version" '
      map(select(has("timestamp") and .finished == 1))
    | map(select(.nixname|capture("(?<name>.*)-(?<version>[^a-zA-Z].*)")|.version|match($version)!=[]))
    | sort_by(.timestamp)
    | reverse
    | .[0]
    ' "$tmpDir/$attr.$system.json")

# ASSUMPTIONS:
# last id is latest
# Find latest result
eval=$(echo "$out" | jq -cr '.jobsetevals|sort|.[-1]')

# Obtain evaluation information
if [ ! -f "$tmpDir/eval.$eval.json" ]; then
    curl --silent -H 'Accept: application/json' "$hydra/eval/$eval" -L > "$tmpDir/eval.$eval.json"
fi
# Obtain nixpkgs revision
rev=$(jq -cr .jobsetevalinputs.nixpkgs.revision "$tmpDir/eval.$eval.json")

job=$(echo "$out" | jq -cr '.job')
# ASSUMPTIONS:
# standard hydraJobs conversion to legacyPackages
attr="legacyPackages.$system.''${job%%".$system"}"

# ASSUMPTIONS:
# our url and rev are for something like github or sourcehut, will fail for git+ssh
if [ -v AS_FLAKEREF ]; then
    printf "%s/%s#%s" "$url" "$rev" "$attr"
    exit 0
fi
cat <<EOF | jq .
{"elements":[
{
    "active": true,
    "url": "$(printf "%s/%s" "$url" "$rev" )",
    "originalUrl": "$url",
    "attrPath": "$attr",
    "storePaths": $(echo "$out" | jq '[.buildoutputs[].path]')
}
],"version": 2}
EOF
    '';
  }) + "/bin/${name}";
}
