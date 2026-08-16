{
  mkDotfiles = root: {
    inherit root;
    path = relative: "${root}/${relative}";
  };
}
