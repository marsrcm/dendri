lib: {
  requireEnv =
    name:
    let
      value = builtins.getEnv name;
    in
    if value == "" then
      throw ''
        Required environment variable ${name} is not set.
        Did you forget to evaluate with --impure?
      ''
    else
      value;
}
