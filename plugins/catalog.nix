# Capacitor API (scope == floxpkgs)
{lib,...}:
# User API
# -- no user input required --

# Plugin API (scope == Using flake)
{context, capacitate,...}:

{
  catalog = lib.genAttrs context.systems (system: builtins.trace "Reserved Attribute for future Catalog" {});
}
