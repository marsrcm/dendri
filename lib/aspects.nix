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
    merge =
      loc: defs:
      (aspectSubmodule.merge loc defs)
      // {
        _name = lib.concatStringsSep "." (lib.drop 1 loc);
      };
    inherit (aspectSubmodule) getSubOptions getSubModules substSubModules;
  };

  aspectFunctionType = lib.types.mkOptionType {
    name = "aspectFunction";
    description = "function returning an aspect";
    check = builtins.isFunction;
    merge =
      loc: defs: arg:
      let
        appliedDefs = map (def: def // { value = def.value arg; }) defs;
      in
      if builtins.all (def: isAspect def.value) appliedDefs then
        (aspectType.merge loc appliedDefs) // { __dendriApplied = true; }
      else
        throw "Function aspect ${lib.concatStringsSep "." (lib.drop 1 loc)} must return an aspect";
  };

  aspectTree =
    lib.types.addCheck (lib.types.attrsOf (
      lib.types.either aspectType (lib.types.either aspectFunctionType aspectTree)
    )) (value: !isAspect value)
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
      walk =
        acc: path: node:
        if builtins.isFunction node then
          acc // { ${lib.concatStringsSep "." path} = node; }
        else if node ? _name then
          acc // { ${node._name} = node; }
        else
          lib.foldl' (acc': name: walk acc' (path ++ [ name ]) node.${name}) acc (builtins.attrNames node);
    in
    walk { } [ ];

  modulesFromAspects =
    aspects:
    let
      flattenedAspects = flattenAspects aspects;
    in
    {
      nixos = lib.mapAttrs (
        _: aspect:
        if builtins.isFunction aspect then
          arg: resolveAspect "nixos" (aspect arg)
        else
          resolveAspect "nixos" aspect
      ) flattenedAspects;
      homeManager = lib.mapAttrs (
        _: aspect:
        if builtins.isFunction aspect then
          arg: resolveAspect "homeManager" (aspect arg)
        else
          resolveAspect "homeManager" aspect
      ) flattenedAspects;
    };
in
{
  inherit evalAspects modulesFromAspects;
}
