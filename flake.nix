{
  description = "Small custom implementation of a dendritic module system for my own personal configs";

  outputs = _: {
    mkLib = import ./lib;
  };
}
