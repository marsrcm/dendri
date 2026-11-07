lib:
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

  # aspectClass -> "nixos" | "homeManager"
  # aspectPath -> previously traversed path that led us to this aspect ie transitively included it
  # aspect -> the aspect we are currently resolving
  resolveAspect' =
    aspectClass: aspectPath: aspect:
    let
      name = aspect._name;
    in
    if builtins.elem name aspectPath then # i.e., if an include was already encountered further up the path
      throw ''
        Aspect dependency cycle:
        ${lib.concatStringsSep " -> " (aspectPath ++ [ name ])}
      ''
    else
      # Let evalModules assign a distinct key to each function application.
      lib.optionalAttrs (!(aspect.__dendriApplied or false)) {
        key = "dendri-aspect:${aspectClass}:${name}";
      }
      // {
        imports = map (resolveAspect' aspectClass (aspectPath ++ [ name ])) aspect.includes ++ [
          aspect.${aspectClass}
        ];
      };

  resolveAspect = aspectClass: aspect: resolveAspect' aspectClass [ ] aspect;

  resolveAspects = aspectClass: aspects: map (resolveAspect aspectClass) aspects;
in
{
  inherit evalAspects resolveAspect resolveAspects;
}
