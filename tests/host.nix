{
  default = {
    expr = {
      foo = {
        host = "example.com";
      };
    };
    expected = {
      foo = {
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

  re = {
    expr = {
      foo = {
        hostRE = "example.*[.]com";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "dest.host";
          data = "$example.*[.]com^";
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

  reWithCaret = {
    expr = {
      foo = {
        hostRE = "^example.*[.]com";
      };
    };
    expectedError.msg = "string without leading";
  };

  reWithDollar = {
    expr = {
      foo = {
        hostRE = "example.*[.]com$";
      };
    };
    expectedError.msg = "trailing";
  };
}
