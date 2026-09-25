{
  default = {
    expr = {
      foo = {
        proto = "tcp";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "protocol";
          data = "tcp";
        };
      };
    };
  };
}
