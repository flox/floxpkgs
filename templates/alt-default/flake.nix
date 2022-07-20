rec {
  description = "Python alternative example template";
  inputs.capacitor.url = "git+ssh://git@github.com/flox/capacitor";
  inputs.capacitor.inputs.root.follows = "/";
  inputs.capacitor.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixpkgs.url = "git+ssh://git@github.com/flox/nixpkgs-flox";

  nixConfig.bash-prompt = "[flox] \\[\\033[38;5;172m\\]λ \\[\\033[0m\\]";

  outputs = _:
    _.capacitor _ ({auto, ...}: {
      devShells.default = {system, ...}:
        auto.usingWith inputs (
          {pkgs, ...}:
            with pkgs;
              pkgs.python39Packages.buildPythonPackage rec {
                name = "alternative";
                nativeBuildInputs =
                  [
                    bats
                    docker-client
                    unzip
                    kubectl
                    coreutils
                    gnugrep
                    findutils
                  ]
                  ++ {
                    x86_64-linux = [
                      # (pkgs.callPackage ((builtins.getFlake "github:NixOS/nixpkgs/1829c5b002d128c9c94f43d8b11c0added3863eb").outPath + "/pkgs/tools/awscli2") {})
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
                  }
                  .${pkgs.system};

                propagatedBuildInputs = [
                  python3Packages.pip
                  python3Packages.allure-pytest
                  python3Packages.kubernetes
                  python3Packages.pytest
                ];

                # =======Environmental Variables=======
                #
                # You can set env vars for common frameworks like Django, Flask, etc here
                HOSTNAME = "localhost";

                # ========Shell Commands===============
                #
                # You may add shell commands that will run in flox develop
                postShellHook = ''
                  echo "Welcome to the Flox Dev Env Project Environment!"
                  echo \# Show versions of packages providing binaries with a bit of color
                  find ${builtins.concatStringsSep " " (map (x: "${x}/bin") nativeBuildInputs)} -exec realpath {} \; | \
                      cut -d- -f2- | cut -d/ -f1 | sort -u | \
                      grep -P --colour=always '(?:^|(?<=[-]))[0-9.]*|$'
                  echo

                '';
              }
        )
        _.nixpkgs.legacyPackages.${system}.stable;
    });
}
