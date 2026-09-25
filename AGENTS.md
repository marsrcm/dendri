# dendri

A small custom implementation of a dendritic module system and misc Nix utilities, inspired by [denful/den](https://github.com/denful/den). Personal-use library, not a general-purpose framework.

## Layout

- `flake.nix` — exposes `mkLib`, which calls `import ./lib`.
- `lib/default.nix` — entry point; takes `lib` and returns the public API:
  - `aspects` — `evalAspects` (evaluate an aspect tree for dedup/merging) and `modulesFromAspects` (flatten a tree of aspects into NixOS/home-manager modules).
  - `system` — `mkDendriHost`, builds a NixOS system from host/aspects with home-manager wired in.
  - `dotfiles` — `mkDotfiles`, produces `{ root, path }` for referencing dotfiles.
  - `env` — `requireEnv`, throws unless an env var is set (evaluation must be `--impure`).
  - `tree` — `importTree` / `importTreeScoped`, recursive `imports` of all `.nix` files under a directory.
- `lib/internal.nix` — `resolveAspect` / `resolveAspects`; resolves `includes` recursively and throws on dependency cycles.
- `lib/aspects.nix` — aspect submodule type (`includes`, `nixos`, `homeManager`), aspect tree type, flattening.
- `lib/nixosSystem.nix` — `mkDendriHost` implementation.
- `lib/env.nix`, `lib/dotfiles.nix`, `lib/tree.nix` — helpers used above.

## Conventions

- Plain Nix library code, formatted with `nixfmt` style (2-space indent, `let ... in`, attribute sets).
- No flake inputs beyond `nixpkgs` consumers pass in `lib`; `mkLib` is a pure function of `lib`.
- No tests or CI; changes are verified by consuming configs (e.g. via `nixos-rebuild` / `nix eval`).
