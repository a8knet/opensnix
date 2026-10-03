{
  default = {
    expr = {
      foo = {
        host = "example.com";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "dest.host";
          data = "example.com";
        };
      };
    };
  };

  regexp = {
    expr = {
      foo = {
        host.regexp = "example.*[.]com";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "dest.host";
          data = "^example.*[.]com$";
        };
      };
    };
  };

  badType = {
    expr = {
      foo = {
        host = 123;
      };
    };
    expectedError.msg = "not of type.*string";
  };

  regexpWithCaret = {
    expr = {
      foo = {
        host.regexp = "^example.*[.]com";
      };
    };
    expectedError.msg = "string without leading";
  };

  regexpWithDollar = {
    expr = {
      foo = {
        host.regexp = "example.*[.]com$";
      };
    };
    expectedError.msg = "trailing";
  };
}
