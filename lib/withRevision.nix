{}: src: version: let
  prefix =
    if src ? revCount
    then "r"
    else "";
  revision = src.revCount or src.shortRev or "dirty";
in "${version}-${prefix}${toString revision}"
