{
  lib,
  resolveAspect,
}:
let
  aspectType = lib.types.submodule (
    { name, ... }: {
      options = {
        _name = lib.mkOption {
          type = lib.types.str;
          default = name;
          internal = true;
          readOnly = true;
        };

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

  aspectsModule = {
    options.aspects = lib.mkOption {
      type = lib.types.lazyAttrsOf aspectType;
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

  modulesFromAspects = aspects: {
    nixos = lib.mapAttrs (_: aspect: resolveAspect "nixos" aspect) aspects;
    homeManager = lib.mapAttrs (_: aspect: resolveAspect "homeManager" aspect) aspects;
  };
in
{
  inherit evalAspects modulesFromAspects;
}
