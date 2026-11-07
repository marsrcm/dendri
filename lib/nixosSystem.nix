{
  lib,
  evalAspects,
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
    let
      evaluatedAspects = evalAspects aspects;
    in
    lib.mapAttrs (
      name: aspect:
      if !lib.isAttrs aspect || !(aspect ? _name) then
        throw "dendri: aspects.hosts.${name} must be a concrete aspect; host functions and nested host namespaces are not supported"
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
    ) (evaluatedAspects.hosts or { });
in
{
  inherit mkNixosConfigurations;
}
