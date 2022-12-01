{
  writeShellApplication,
  substituteAll,
  pkgs,
  bashInteractive,
}:
writeShellApplication {
  name = "podman-runner";

  runtimeInputs = [pkgs.podman bashInteractive];

  text = builtins.readFile (substituteAll {
    src = ./src/runner.sh;
    container_main = ./src/container-main.sh;
  });
}
