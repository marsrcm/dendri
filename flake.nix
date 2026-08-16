{
  description = "Small custom implementation of a dendritic module system and other utilities for my own personal configs";

  outputs = _: {
    mkLib = import ./lib;
  };
}
