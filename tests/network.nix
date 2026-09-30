{
  default = {
    expr = {
      foo = {
        network = "10.0.0.0/8";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "dest.network";
          data = "10.0.0.0/8";
        };
      };
    };
  };

  dst = {
    expr = {
      foo = {
        dstNetwork = "10.0.0.0/8";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "dest.network";
          data = "10.0.0.0/8";
        };
      };
    };
  };

  src = {
    expr = {
      foo = {
        srcNetwork = "10.0.0.0/8";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "source.network";
          data = "10.0.0.0/8";
        };
      };
    };
  };

  regexp = {
    expr = {
      foo = {
        network.regexp = "10\\..*";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "dest.network";
          data = "$10\\..*^";
        };
      };
    };
  };

  dstRegexp = {
    expr = {
      foo = {
        dstNetwork.regexp = "10\\..*";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "dest.network";
          data = "$10\\..*^";
        };
      };
    };
  };

  srcRegexp = {
    expr = {
      foo = {
        srcNetwork.regexp = "10\\..*";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "source.network";
          data = "$10\\..*^";
        };
      };
    };
  };

  regexpWithCaret = {
    expr = {
      foo = {
        network.regexp = "^10\\..*";
      };
    };
    expectedError.msg = "string without leading";
  };

  dstRegexpWithDollar = {
    expr = {
      foo = {
        dstNetwork.regexp = "10\\..*$";
      };
    };
    expectedError.msg = "trailing";
  };

  srcRegexpWithBoth = {
    expr = {
      foo = {
        srcNetwork.regexp = "^10\\..*$";
      };
    };
    expectedError.msg = "string without leading";
  };
}
