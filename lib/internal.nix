lib:
let
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
in
{
  inherit resolveAspect resolveAspects;
}
