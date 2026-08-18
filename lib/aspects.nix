{
  lib,
  resolveAspect,
}:
let
  aspectSubmodule = lib.types.submodule (
    { name, ... }: {
      options = {
        includes = lib.mkOption {
          # TODO: try changing this type to aspectType
          type = lib.types.listOf lib.types.raw;
          default = [ ];
        };

        nixos = lib.mkOption {
          type = lib.types.deferredModule;
          default = { };
        };

        homeManager = lib.mkOption {
          type = lib.types.deferredModule;
          default = { };
        };
      };
    }
  );


  isAspect = value: lib.isAttrs value && (value ? includes || value ? nixos || value ? homeManager);

  aspectType = lib.types.mkOptionType {
    name = "aspect";
    description = "aspect";
    check = isAspect;
    merge = loc: defs:
      (aspectSubmodule.merge loc defs)
      // {
        _name = lib.concatStringsSep "." (lib.drop 1 loc);
      };
    inherit (aspectSubmodule) getSubOptions getSubModules substSubModules;
  };


  aspectTree =
    lib.types.addCheck
      (lib.types.attrsOf (lib.types.either aspectType aspectTree))
      (value: !isAspect value)
    // {
    description = "Aspect Tree";
    descriptionClass = "noun";
  };

  aspectsModule = {
    options.aspects = lib.mkOption {
      type = aspectTree;
      default = { };
    };
  };

  evalAspects =
    aspectModules:
    (lib.evalModules {
      modules = [
        aspectsModule
      ]
      ++ aspectModules;
    }).config.aspects;

  flattenAspects =
    let
      walk = acc: node:
        if node ? _name then
          acc // { ${node._name} = node; }
        else
          lib.foldl'
            (acc': name: walk acc' node.${name})
            acc
            (builtins.attrNames node);
    in
      walk { };

  modulesFromAspects = aspects:
    let
      flattenedAspects = flattenAspects aspects;
    in
      {
        nixos = lib.mapAttrs (_: aspect: resolveAspect "nixos" aspect) flattenedAspects;
        homeManager = lib.mapAttrs (_: aspect: resolveAspect "homeManager" aspect) flattenedAspects;
      };
in
{
  inherit evalAspects modulesFromAspects;
}
