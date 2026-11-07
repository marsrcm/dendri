{
  lib,
  evalAspects,
  resolveAspect,
}:
let
  mkNixosConfigurations =
    {
      aspects,
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
    if !(inputs ? nixpkgs.lib.nixosSystem) then
      throw "dendri: mkNixosConfigurations requires inputs.nixpkgs.lib.nixosSystem"
    else
      lib.mapAttrs (
        name: aspect:
        if !lib.isAttrs aspect || !(aspect ? _name) then
          throw "dendri: aspects.hosts.${name} must be a concrete aspect; host functions and nested host namespaces are not supported"
        else
          inputs.nixpkgs.lib.nixosSystem {
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
