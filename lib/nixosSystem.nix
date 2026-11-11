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
      specialArgs ? { },
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
          inherit specialArgs;
          modules = [
            (resolveAspect "nixos" aspect)
            (
              { options, ... }:
              {
                config = lib.optionalAttrs (lib.hasAttrByPath [ "home-manager" "sharedModules" ] options) {
                  home-manager.sharedModules = [ (resolveAspect "homeManager" aspect) ];
                };
              }
            )
          ];
        }
    ) (evaluatedAspects.hosts or { });
in
{
  inherit mkNixosConfigurations;
}
