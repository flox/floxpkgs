{ python3, python3Packages }:

let
  # Prefix for python executable name.
  pyprefix = "ds";
  # Python version to be wrapped.
  python = python3;
  pythonPackages = python3Packages;
  # Attribute set of python modules -> packages that they come
  # from, used to drive both the build and "smoke test".
  extraLibModules = {
    pandas = "pandas";
    tensorflow = "tensorflow";
    torch = "pytorch";
  };

in
  python.buildEnv.override {
    ignoreCollisions = true;
    extraLibs = map (pyPkg: pythonPackages.${pyPkg}) (builtins.attrValues extraLibModules);
    postBuild = ''
      # Rename and retain only the default python binaries to minimize confusion.
      tmpdir=`mktemp -d`
      mv $out/bin/python* $tmpdir
      rm -rf $out/bin
      mv $tmpdir $out/bin
      ( cd $out/bin && for i in python*; do mv $i ${pyprefix}$i; done )
      # A quick "smoke test" to ensure we have all the necessary imports.
      for i in ${builtins.toString (builtins.attrNames extraLibModules)}; do
        ( set -x && $out/bin/${pyprefix}python -c "import $i" )
      done
    '';
  }
