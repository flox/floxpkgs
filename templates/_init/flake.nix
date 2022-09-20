{
  

  # Declaration of external resources
  # =================================

  # =================================



  # Template DO NOT EDIT
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  description = "Floxpkgs/Project Template";
  outputs = args @ {capacitor, ...}: capacitor args (import ./flox.nix);
  nixConfig.bash-prompt = "[flox] \\[\\033[38;5;172m\\]λ \\[\\033[0m\\]";
  # could be inferred?
  inputs.floxpkgs.url = "github:flox/floxpkgs";
  inputs.capacitor.url = "github:flox/capacitor?ref=v0";
  inputs.capacitor.inputs.root.follows = "/";
  inputs.flox-extras.url = "github:flox/flox-extras";
  inputs.flox-extras.inputs.capacitor.follows = "capacitor";
  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
}
