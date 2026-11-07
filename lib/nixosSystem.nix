{
  lib,
  resolveAspect,
}:
let
  mkNixosConfigurations =
    {
      aspects,
      nixosSystem,
      inputs,
      sharedSpecialArgs ? { },
      homeManagerModule ? { inputs, ... }: {
        imports = [ inputs.home-manager.nixosModules.home-manager ];
        home-manager = {
          useGlobalPkgs = lib.mkDefault true;
          useUserPackages = lib.mkDefault true;
          extraSpecialArgs = { inherit inputs; };
        };
      },
    }:
    lib.mapAttrs (
      name: aspect:
      if !lib.isAttrs aspect || !(aspect ? _name) then
        throw "dendri: aspects.hosts.${name} must be a concrete, evaluated aspect; host functions and nested host namespaces are not supported"
      else
        nixosSystem {
          system = null;
          specialArgs = {
            inherit inputs;
          }
          // sharedSpecialArgs;
          modules = [
            (resolveAspect "nixos" aspect)
            homeManagerModule
            {
              home-manager.sharedModules = [ (resolveAspect "homeManager" aspect) ];
            }
          ];
        }
    ) (aspects.hosts or { });
in
{
  inherit mkNixosConfigurations;
}
