#!/usr/bin/env bats
# to run these tests, first run 'flox develop'
setup() {
  export NOOP="NOOP"    
}

@test "test curl" {
  run curl
  [[ "${lines[0]}" =~ "for more information" ]]
}


@test "test by curl is sourced from flox" {
  run which curl
  [[ "${lines[0]}" =~ "/nix/store" ]]
}

@test "test by unzip" {
  run unzip
  [[ "${lines[0]}" =~ "by Info-ZIP" ]]
}

@test "test by unzip is sourced from flox" {
  run which unzip
  [[ "${lines[0]}" =~ "/nix/store" ]]
}

@test "test GNUgrep" {
  run grep --help
  [[ "${lines[0]}" =~ "Usage: grep [OPTION]... PATTERNS [FILE]..." ]]
}

@test "test GNUgrep is sourced from flox" {
  run which grep
  [[ "${lines[0]}" =~ "/nix/store" ]]
}

@test "test coreutils" {
  run cat --help
  [[ "${lines[0]}" =~ "Usage: cat [OPTION]... [FILE]..." ]]
}


@test "test coreutils is sourced from flox" {
  run which cat
  [[ "${lines[0]}" =~ "/nix/store" ]]
}

@test "flox search" {
  run flox search "kubectl Kubernetes"
  [[ "$output" =~ "kubernetes" ]]
}
