{
  path = {
    expr = {
      foo = {
        processPath = "/usr/bin/firefox";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "process.path";
          data = "/usr/bin/firefox";
        };
      };
    };
  };

  command = {
    expr = {
      foo = {
        processCommand = "firefox";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "process.command";
          data = "firefox";
        };
      };
    };
  };

  pathRE = {
    expr = {
      foo = {
        processPathRE = "/usr/bin/.*";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "process.path";
          data = "$/usr/bin/.*^";
        };
      };
    };
  };

  commandRE = {
    expr = {
      foo = {
        processCommandRE = "fire.*";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "process.command";
          data = "$fire.*^";
        };
      };
    };
  };

  pathREWithCaret = {
    expr = {
      foo = {
        processPathRE = "^/usr/bin/.*";
      };
    };
    expectedError.msg = "string without lead";
  };

  commandREWithDollar = {
    expr = {
      foo = {
        processCommandRE = "fire.*$";
      };
    };
    expectedError.msg = "trailing";
  };

  pathREWithBoth = {
    expr = {
      foo = {
        processPathRE = "^/usr/bin/.*$";
      };
    };
    expectedError.msg = "string without lead";
  };
}
