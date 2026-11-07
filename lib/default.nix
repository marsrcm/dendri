lib:
let
  internal = import ./internal.nix lib;
in
{
  system = import ./nixosSystem.nix {
    inherit lib;
    inherit (internal) evalAspects resolveAspect;
  };

  dotfiles = import ./dotfiles.nix;

  env = import ./env.nix lib;

  tree = import ./tree.nix;
}
