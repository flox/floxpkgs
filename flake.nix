{

  description = "Index flake for floxkgs";

  inputs.capacitor.url = "github:flox/capacitor?ref=v0";
  inputs.floxpkgs = {
    url = "github:flox/floxpkgs";
    inputs.index.follows = "/";
    inputs.capacitor.follows = "capacitor";
  };


  # User added or managed inputs
  inputs = {
    nixpkgs = {
      url = "github:flox/nixpkgs-flox";
    };

    flox = {
      url = "github:flox/flox";
      flake = false;
      inputs.capacitor.follows = "capacitor";
    };

    builtfilter = {
      url = "github:flox/builtfilter?ref=builtfilter-rs";
      inputs.capacitor.follows = "capacitor";
    };

  };

  outputs = {...} @ args : args;

}
