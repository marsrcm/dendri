lib:
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
      {
        imports = map (resolveAspect' aspectClass (aspectPath ++ [ name ])) aspect.includes ++ [
          aspect.${aspectClass}
        ];
      };

  resolveAspect = aspectClass: aspect: resolveAspect' aspectClass [ ] aspect;

  resolveAspects = aspectClass: aspects: map (resolveAspect aspectClass) aspects;

  mkDendriHost =
    {
      nixosSystem,
      homeManagerModule,
    }:
    host:
    let
      hostModules = {
        nixos = {
          imports = resolveAspects "nixos" (host.aspects or [ ]);
        };

        homeManager = {
          imports = resolveAspects "homeManager" (host.aspects or [ ]);
        };
      };
    in
    nixosSystem {
      system = host.system;
      modules = [

        hostModules.nixos
        (host.nixos or { })

        homeManagerModule

        {
          home-manager.users = lib.mapAttrs (_: user: {
            imports = [
              hostModules.homeManager
              (user.homeManager or { })
            ];
          }) (host.users or { });
        }
      ];
    };

  modulesFromAspects = aspects: {
    nixos = lib.mapAttrs (_: aspect: resolveAspect "nixos" aspect) aspects;
    homeManager = lib.mapAttrs (_: aspect: resolveAspect "homeManager" aspect) aspects;
  };
in
{
  inherit evalAspects modulesFromAspects mkDendriHost;
}
