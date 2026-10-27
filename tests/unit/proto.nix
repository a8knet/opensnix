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

  caseInsensitive = {
    expr = {
      foo = {
        proto = "TCP";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "protocol";
          data = "TCP";
        };
      };
    };
  };

  typoRejected = {
    expr = {
      foo = {
        proto = "tpc";
      };
    };
    expectedError.msg = "protocol, one of";
  };
}
