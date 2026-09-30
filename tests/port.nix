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

  badPortType = {
    expr = {
      foo = {
        port = "443";
      };
    };
    expectedError.msg = "not of type.*signed integer";
  };

  badDstPortType = {
    expr = {
      foo = {
        dstPort = "x";
      };
    };
    expectedError.msg = "not of type.*signed integer";
  };

  badSrcPortType = {
    expr = {
      foo = {
        srcPort = "x";
      };
    };
    expectedError.msg = "not of type.*signed integer";
  };

  regexp = {
    expr = {
      foo = {
        port.regexp = "80|443";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "dest.port";
          data = "$80|443^";
        };
      };
    };
  };

  dstRegexp = {
    expr = {
      foo = {
        dstPort.regexp = "80|443";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "dest.port";
          data = "$80|443^";
        };
      };
    };
  };

  srcRegexp = {
    expr = {
      foo = {
        srcPort.regexp = "1024-65535";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "source.port";
          data = "$1024-65535^";
        };
      };
    };
  };

  regexpWithCaret = {
    expr = {
      foo = {
        port.regexp = "^80|443";
      };
    };
    expectedError.msg = "string without leading";
  };

  regexpWithDollar = {
    expr = {
      foo = {
        port.regexp = "80|443$";
      };
    };
    expectedError.msg = "trailing";
  };
}
