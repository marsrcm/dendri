{
  lib,
  resolveAspects,
}:
let
  mkDendriHost =
    {
      nixosSystem,
      homeManagerModule,
      sharedSpecialArgs ? { },
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
      specialArgs = sharedSpecialArgs // (host.specialArgs or { });
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
in
{
  inherit mkDendriHost;
}
