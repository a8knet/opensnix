{
  simple = {
    expr = {
      foo = {
        processEnv = {
          LD_PRELOAD = "/tmp/evil.so";
        };
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "process.env.LD_PRELOAD";
          data = "/tmp/evil.so";
        };
      };
    };
  };

  dotted = {
    expr = {
      foo = {
        processEnv.HTTPS_PROXY = "http://proxy:3128";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "process.env.HTTPS_PROXY";
          data = "http://proxy:3128";
        };
      };
    };
  };

  regexp = {
    expr = {
      foo = {
        processEnv = {
          LD_PRELOAD.regexp = "/tmp/.*";
        };
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "process.env.LD_PRELOAD";
          data = "^(?:/tmp/.*)$";
        };
      };
    };
  };

  multipleVariables = {
    expr = {
      foo = {
        processEnv = {
          HTTPS_PROXY = "http://proxy:3128";
          LD_PRELOAD = "/tmp/evil.so";
        };
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "simple";
              operand = "process.env.HTTPS_PROXY";
              data = "http://proxy:3128";
            }
            {
              type = "simple";
              operand = "process.env.LD_PRELOAD";
              data = "/tmp/evil.so";
            }
          ];
        };
      };
    };
  };

  withOtherCondition = {
    expr = {
      foo = {
        processEnv = {
          LD_PRELOAD = "/tmp/evil.so";
        };
        processPath = "/usr/bin/curl";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "simple";
              operand = "process.env.LD_PRELOAD";
              data = "/tmp/evil.so";
            }
            {
              type = "simple";
              operand = "process.path";
              data = "/usr/bin/curl";
            }
          ];
        };
      };
    };
  };

  insideDeny = {
    expr = {
      foo = {
        deny.processEnv = {
          LD_PRELOAD = "/tmp/evil.so";
        };
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "deny";
        operator = {
          type = "simple";
          operand = "process.env.LD_PRELOAD";
          data = "/tmp/evil.so";
        };
      };
    };
  };

  groupInheritance = {
    expr = {
      web = {
        processEnv = {
          LD_PRELOAD = "/tmp/evil.so";
        };
        rules = {
          curl = {
            processEnv = {
              HTTPS_PROXY = "http://proxy:3128";
            };
            processPath = "/usr/bin/curl";
          };
          override = {
            processEnv = {
              LD_PRELOAD = "/tmp/other.so";
            };
          };
        };
      };
    };
    expected = {
      opensnix-web-curl = {
        name = "opensnix-web-curl";
        action = "allow";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "simple";
              operand = "process.env.HTTPS_PROXY";
              data = "http://proxy:3128";
            }
            {
              type = "simple";
              operand = "process.env.LD_PRELOAD";
              data = "/tmp/evil.so";
            }
            {
              type = "simple";
              operand = "process.path";
              data = "/usr/bin/curl";
            }
          ];
        };
      };
      opensnix-web-override = {
        name = "opensnix-web-override";
        action = "allow";
        operator = {
          type = "simple";
          operand = "process.env.LD_PRELOAD";
          data = "/tmp/other.so";
        };
      };
    };
  };

  emptyAttrset = {
    expr = {
      foo = {
        processEnv = { };
      };
    };
    expectedError.msg = "no environment variables";
  };

  invalidVariableName = {
    expr = {
      foo = {
        processEnv = {
          "1LD_PRELOAD" = "/tmp/evil.so";
        };
      };
    };
    expectedError.msg = "environment variable";
  };

  regexpWithCaret = {
    expr = {
      foo = {
        processEnv = {
          LD_PRELOAD.regexp = "^/tmp/.*";
        };
      };
    };
    expectedError.msg = "string without lead";
  };
}
