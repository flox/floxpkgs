{ callPackage, pkgs, xcodeenv, electron }:

let
  callVSCodePackage = pkg: attrs: let p = callPackage pkg attrs; in p // {
    withExtensions = callPackage ./with-extensions.nix {
      vscode = p;
    };
  };

in {
  vscode = callVSCodePackage ./vscode.nix { };
  vscodium = callVSCodePackage ./vscodium.nix { };
  vscode-oss = callVSCodePackage ./oss.nix { electron = electron.electron_17_4_7;
      inherit (pkgs.darwin.apple_sdk.frameworks) Cocoa;
      inherit xcodeenv;
      };
}
