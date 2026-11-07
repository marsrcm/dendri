# dendri

A small custom implementation of a dendritic module system and misc Nix utilities, inspired by [denful/den](https://github.com/denful/den). Personal-use library, not a general-purpose framework.

## Layout

- `flake.nix` — exposes `mkLib`, which calls `import ./lib`.
- `lib/default.nix` — entry point; takes `lib` and returns the public API:
  - `system` — `mkNixosConfigurations`, evaluates its `aspects` module list and builds NixOS systems from `aspects.hosts.<name>` with home-manager wired in.
  - `dotfiles` — `mkDotfiles`, produces `{ root, path }` for referencing dotfiles.
  - `env` — `requireEnv`, throws unless an env var is set (evaluation must be `--impure`).
  - `tree` — `importTree` / `importTreeScoped`, recursive `imports` of `.nix` files under a directory, skipping files and directories whose names start with `_`.
- `lib/internal.nix` — private aspect types and `evalAspects`, plus `resolveAspect` / `resolveAspects` for recursive includes and cycle detection.
- `lib/nixosSystem.nix` — `mkNixosConfigurations` implementation.
- `lib/env.nix`, `lib/dotfiles.nix`, `lib/tree.nix` — helpers used above.

`mkNixosConfigurations.aspects` takes an unevaluated list of modules (paths,
attribute sets, functions, or `tree.importTree` results). Base and specific aspect
modules are composed in that list and evaluated together internally.
System construction uses `inputs.nixpkgs.lib.nixosSystem`, which must exist.

## Conventions

- Plain Nix library code, formatted with `nixfmt` style (2-space indent, `let ... in`, attribute sets).
- No flake inputs beyond `nixpkgs` consumers pass in `lib`; `mkLib` is a pure function of `lib`.
- No tests or CI; changes are verified by consuming configs (e.g. via `nixos-rebuild` / `nix eval`).
