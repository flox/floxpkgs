# Capacitor API (scope == floxpkgs)
{lib, ...}:
# User API
# -- no user input required --

# Plugin API (scope == Using flake)
{context, capacitate,...}:

{
  __reflect.finalFlake.config.stabilities = {
    stable = context.root.inputs.nixpkgs.stable;
    staging = context.root.inputs.nixpkgs.staging;
    unstable = context.root.inputs.nixpkgs.unstable;
    default = context.root.inputs.nixpkgs.stable;
  };
}
