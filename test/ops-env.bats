#!/usr/bin/env bats
# to run these tests, first run 'flox develop'
setup() {
  export NOOP="NOOP"    
}

@test "test curl" {
  run curl
  [[ "${lines[0]}" =~ "for more information" ]]
}


@test "test by unzip" {
  run unzip
  [[ "${lines[0]}" =~ "by Info-ZIP" ]]
}


@test "test GNUgrep" {
  run grep --help
  [[ "${lines[0]}" =~ "Usage: grep [OPTION]... PATTERNS [FILE]..." ]]
}

@test "test coreutils" {
  run cat --help
  [[ "${lines[0]}" =~ "Usage: cat [OPTION]... [FILE]..." ]]
}

@test "test which" {
  run which --help
  [[ "${lines[0]}" =~ "Usage: which [options] [--] COMMAND [...]" ]]
}


@test "test python pip" {
  run python -c "import pip;print(pip)"
  [[ "${lines[0]}" =~ "<module 'pip' from '/nix/store" ]]
}

@test "test python allure-pytest" {
  run python -c "import allure;print(allure)"
  [[ "${lines[0]}" =~ "<module 'allure' from '/nix/store" ]]
}

@test "test python pytest" {
  run python -c "import pytest;print(pytest)"
  [[ "${lines[0]}" =~ "<module 'pytest' from '/nix/store" ]]
}


@test "test vscode extensions" {
  
  run code --list-extensions
  [[ "$output" =~ "ms-python.pylint" ]]
  [[ "$output" =~ "ms-python.python" ]]
  [[ "$status" -eq 0 ]]

}

@test "flox search" {
  run flox search "kubectl Kubernetes"
  [[ "$output" =~ "Kubernetes" ]]
}
