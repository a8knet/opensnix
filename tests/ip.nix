{
  default = {
    expr = {
      foo = {
        ip = "1.2.3.4";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "dest.ip";
          data = "1.2.3.4";
        };
      };
    };
  };

  dst = {
    expr = {
      foo = {
        dstIp = "1.2.3.4";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "dest.ip";
          data = "1.2.3.4";
        };
      };
    };
  };

  src = {
    expr = {
      foo = {
        srcIp = "1.2.3.4";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "source.ip";
          data = "1.2.3.4";
        };
      };
    };
  };

  regexp = {
    expr = {
      foo = {
        ip.regexp = "192\\.168\\..*";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "dest.ip";
          data = "^192\\.168\\..*$";
        };
      };
    };
  };

  dstRegexp = {
    expr = {
      foo = {
        dstIp.regexp = "192\\.168\\..*";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "dest.ip";
          data = "^192\\.168\\..*$";
        };
      };
    };
  };

  srcRegexp = {
    expr = {
      foo = {
        srcIp.regexp = "192\\.168\\..*";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "source.ip";
          data = "^192\\.168\\..*$";
        };
      };
    };
  };

  regexpWithCaret = {
    expr = {
      foo = {
        ip.regexp = "^192\\.168\\..*";
      };
    };
    expectedError.msg = "string without leading";
  };

  dstRegexpWithDollar = {
    expr = {
      foo = {
        dstIp.regexp = "192\\.168\\..*$";
      };
    };
    expectedError.msg = "trailing";
  };

  srcRegexpWithBoth = {
    expr = {
      foo = {
        srcIp.regexp = "^192\\.168\\..*$";
      };
    };
    expectedError.msg = "string without leading";
  };
}
