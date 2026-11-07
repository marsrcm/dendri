let
  nixFiles =
    dir:
    let
      entries = builtins.readDir dir;
    in
    builtins.concatLists (
      map (
        name:
        let
          type = entries.${name};
          path = dir + "/${name}";
        in
        # Reserve underscore-prefixed files and directories for explicit imports.
        if builtins.substring 0 1 name == "_" then
          [ ]
        else if type == "directory" then
          nixFiles path
        else if type == "regular" && builtins.match ".*\\.nix" name != null then
          [ path ]
        else
          [ ]
      ) (builtins.attrNames entries)
    );
  mkImportTree = scope: root: {
    imports = map (path: builtins.scopedImport scope path) (nixFiles root);
  };

  importTree = root: { imports = nixFiles root; };
  importTreeScoped = scope: root: mkImportTree scope root;
in
{
  inherit importTree importTreeScoped;
}
