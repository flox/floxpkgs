{
  self,
  writeShellApplication,
  name ? "flox-install",
  system,
}: {
  type = "app";
  program =
    (writeShellApplication {
      inherit name;
      runtimeInputs = [];
      text = ''
        nix \
        --extra-experimental-features 'nix-command flakes' \
        profile install --impure github:flox/floxpkgs#evalCatalog.${system}.stable.flox "$@"
      '';
    })
    + "/bin/${name}";
}
