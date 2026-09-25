{
  default = {
    expr = {
      foo = {
        port = 123;
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "dest.port";
          data = "123";
        };
      };
    };
  };

  dst = {
    expr = {
      foo = {
        dstPort = 123;
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "dest.port";
          data = "123";
        };
      };
    };
  };

  src = {
    expr = {
      foo = {
        srcPort = 123;
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "source.port";
          data = "123";
        };
      };
    };
  };
}
