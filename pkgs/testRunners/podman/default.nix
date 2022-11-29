{
  writeShellApplication,
  substituteAll,
  podman,
  bashInteractive,
}:
writeShellApplication {
  name = "podman-runner";

  runtimeInputs = [podman bashInteractive];

  text = builtins.readFile (substituteAll {
    src = ./src/runner.sh;
    container_main = ./src/container-main.sh;
  });
}
