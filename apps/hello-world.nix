{
  writeShellApplication,
  curl,
  bat,
  name ? "hello",
  data ? {
    host = "asdf";
    port = 2;
  },
  ...
}: {
  type = "app";
  program =
    (writeShellApplication {
      inherit name;
      runtimeInputs = [curl bat];
      text = ''
        curl -v ${data.host}:${toString data.port} | bat
        echo
        echo GOODBYE ${name}
      '';
    })
    + "/bin/${name}";
}
