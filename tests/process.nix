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

  pathRegexp = {
    expr = {
      foo = {
        processPath.regexp = "/usr/bin/.*";
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

  commandRegexp = {
    expr = {
      foo = {
        processCommand.regexp = "fire.*";
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

  pathRegexpWithCaret = {
    expr = {
      foo = {
        processPath.regexp = "^/usr/bin/.*";
      };
    };
    expectedError.msg = "string without lead";
  };

  commandRegexpWithDollar = {
    expr = {
      foo = {
        processCommand.regexp = "fire.*$";
      };
    };
    expectedError.msg = "trailing";
  };

  pathRegexpWithBoth = {
    expr = {
      foo = {
        processPath.regexp = "^/usr/bin/.*$";
      };
    };
    expectedError.msg = "string without lead";
  };
}
