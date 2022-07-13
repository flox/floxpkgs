#!/usr/bin/env bats
# to run these tests, first run 'flox develop'
setup() {
  export NOOP="NOOP"    
}


@test "test python click" {
  run python -c "import click;print(click)"
  [[ ! "${lines[0]}" =~ "<module 'click' from '/nix/store" ]]
}

@test "test python black" {
  run python -c "import black;print(black)"
  [[ ! "${lines[0]}" =~ "<module 'allure' from '/nix/store" ]]
}

@test "test source of lint" {
  run which lint
  [[ "${lines[0]}" =~ "/nix/store" ]]
}
