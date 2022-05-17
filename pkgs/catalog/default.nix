{
  buildGoModule,
  fetchFrom,
  inputs,
} @ args:
buildGoModule rec {
  pname = "catalog";
  version = "1.0.0+r${toString src.lock.revCount}";

  src = fetchFrom inputs "git+ssh://git@github.com/flox/catalog?ref=master";

}
