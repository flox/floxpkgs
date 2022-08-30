{

  description = "Index flake for floxkgs";

  inputs.capacitor.follows = "floxpkgs/capacitor";

  inputs.nixpkgs.url = "github:flox/nixpkgs-flox";
  # .url = "github:flox/capacitor?ref=v0";
    

  inputs.floxpkgs = {
    # needs to be set by us
    url = "github:flox/floxpkgs";
    inputs.index.follows = "/";
    inputs.nixpkgs.follows = "nixpkgs";
  };


  # User added or managed inputs
  inputs = {
   

    flox = {
      url = "github:flox/flox";
      flake = false;
      inputs.capacitor.follows = "capacitor";
    };

    flox-extras = {
      url = "github:flox/flox-extras";
      inputs.capacitor.follows = "capacitor";
    };

    builtfilter = {
      url = "github:flox/builtfilter?ref=builtfilter-rs";
      inputs.capacitor.follows = "capacitor";
    };

  };

  outputs = {...} @ args : args;

}
