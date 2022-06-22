rec {
  description = "Template using specific versions";

  inputs.capacitor.url = "git+ssh://git@github.com/flox/capacitor";
  inputs.capacitor.inputs.root.follows = "/";

  inputs.nixpkgs.url = "git+ssh://git@github.com/flox/nixpkgs-flox";
  inputs.nixpkgs.inputs.capacitor.follows = "capacitor";

  inputs.floxpkgs.url = "git+ssh://git@github.com/flox/floxpkgs";
  inputs.floxpkgs.inputs.capacitor.follows = "capacitor";
  inputs.floxpkgs.inputs.nixpkgs.follows = "nixpkgs";
  inputs.floxpkgs.inputs.default.follows = "/";

  # TODO: preferred method below would only need this. (https://github.com/NixOS/nix/issues/5790)
  # inputs.floxpkgs.url = "git+ssh://git@github.com/flox/floxpkgs";
  # inputs.floxpkgs.inputs.capacitor.inputs.root.follows = "/";

  nixConfig.bash-prompt = "[flox] \\[\\033[38;5;172m\\]λ \\[\\033[0m\\]";

  outputs = _:
    _.capacitor _ ({floxpkgs, ...}: {
      devShells.default = _.capacitor.lib.mkFloxShell _ ./flox.toml _.self.__pins;
      apps = floxpkgs.apps;

      # AUTO-MANAGED AFTER THIS POINT ##################################
      # AUTO-MANAGED AFTER THIS POINT ##################################
      # AUTO-MANAGED AFTER THIS POINT ##################################
      __pins.versions = {
        x86_64-linux = [
          (builtins.getFlake "github:NixOS/nixpkgs/1829c5b002d128c9c94f43d8b11c0added3863eb").legacyPackages.x86_64-linux.awscli2
          (builtins.getFlake "github:NixOS/nixpkgs/43cc623340ac0723fb73c1bce244bb6d791c5bb9").legacyPackages.x86_64-linux.curl
          (builtins.getFlake "github:NixOS/nixpkgs/4d922730369d1c468cc4ef5b2fc30fd4200530e0").legacyPackages.x86_64-linux.kubernetes-helm
        ];
        aarch64-darwin = [
          (builtins.getFlake "github:NixOS/nixpkgs/de7510053c905d54ce1c574695995ad3ff7c505f").legacyPackages.aarch64-darwin.awscli2
          (builtins.getFlake "github:NixOS/nixpkgs/dad7a0fd1a1b6ab257ba0b212077324a97dbeaa7").legacyPackages.aarch64-darwin.curl
          (builtins.getFlake "github:NixOS/nixpkgs/6b3bf39220430ad0275f51492a6846d4a6b92cb5").legacyPackages.aarch64-darwin.kubernetes-helm
        ];
        aarch64-linux = [
          (builtins.getFlake "github:NixOS/nixpkgs/1829c5b002d128c9c94f43d8b11c0added3863eb").legacyPackages.aarch64-linux.awscli2
          (builtins.getFlake "github:NixOS/nixpkgs/43cc623340ac0723fb73c1bce244bb6d791c5bb9").legacyPackages.aarch64-linux.curl
          (builtins.getFlake "github:NixOS/nixpkgs/4d922730369d1c468cc4ef5b2fc30fd4200530e0").legacyPackages.aarch64-linux.kubernetes-helm
        ];
        x86_64-darwin = [
          (builtins.getFlake "github:NixOS/nixpkgs/1829c5b002d128c9c94f43d8b11c0added3863eb").legacyPackages.x86_64-darwin.awscli2
          (builtins.getFlake "github:NixOS/nixpkgs/43cc623340ac0723fb73c1bce244bb6d791c5bb9").legacyPackages.x86_64-darwin.curl
          (builtins.getFlake "github:NixOS/nixpkgs/4d922730369d1c468cc4ef5b2fc30fd4200530e0").legacyPackages.x86_64-darwin.kubernetes-helm
        ];
      };
      __pins.vscode-extensions = [
      ];
    });
}
