lib:
let
  internal = import ./internal.nix lib;
in
{
  aspects = import ./aspects.nix {
    inherit lib;
    inherit (internal) resolveAspect;
  };

  system = import ./nixosSystem.nix {
    inherit lib;
    inherit (internal) resolveAspects;
  };
}
