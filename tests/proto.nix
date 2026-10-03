{
  default = {
    expr = {
      foo = {
        proto = "tcp";
      };
    };
    expected = {
      opensnix-foo = {
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
