{
  default = {
    expr = {
      foo = {
        ip = "1.2.3.4";
      };
    };
    expected = {
      foo = {
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
      foo = {
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
      foo = {
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

  re = {
    expr = {
      foo = {
        ipRE = "192\\.168\\..*";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "dest.ip";
          data = "$192\\.168\\..*^";
        };
      };
    };
  };

  dstRe = {
    expr = {
      foo = {
        dstIpRE = "192\\.168\\..*";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "dest.ip";
          data = "$192\\.168\\..*^";
        };
      };
    };
  };

  srcRe = {
    expr = {
      foo = {
        srcIpRE = "192\\.168\\..*";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "source.ip";
          data = "$192\\.168\\..*^";
        };
      };
    };
  };

  reWithCaret = {
    expr = {
      foo = {
        ipRE = "^192\\.168\\..*";
      };
    };
    expectedError.msg = "string without leading";
  };

  dstReWithDollar = {
    expr = {
      foo = {
        dstIpRE = "192\\.168\\..*$";
      };
    };
    expectedError.msg = "trailing";
  };

  srcReWithBoth = {
    expr = {
      foo = {
        srcIpRE = "^192\\.168\\..*$";
      };
    };
    expectedError.msg = "string without leading";
  };
}
