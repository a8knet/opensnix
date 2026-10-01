let
  mkMockPkg =
    {
      pname,
      outPath,
      mainProgram ? pname,
    }:
    {
      type = "derivation";
      inherit outPath pname;
      name = "${pname}-1.0";
      meta = {
        inherit mainProgram;
      };
      bin = {
        inherit outPath pname;
        meta = {
          inherit mainProgram;
        };
      };
    };

  firefox = mkMockPkg {
    pname = "firefox";
    outPath = "/nix/store/aaaa-firefox";
    mainProgram = "firefox";
  };

  curl = mkMockPkg {
    pname = "curl";
    outPath = "/nix/store/bbbb-curl";
    mainProgram = "curl";
  };
in
{
  barePackage = {
    expr = {
      foo = {
        package = firefox;
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "process.path";
          data = "/nix/store/aaaa-firefox/bin/firefox";
        };
      };
    };
  };

  explicitValue = {
    expr = {
      foo = {
        package = {
          value = firefox;
        };
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "process.path";
          data = "/nix/store/aaaa-firefox/bin/firefox";
        };
      };
    };
  };

  wrappedValue = {
    expr = {
      foo = {
        package = {
          value = firefox;
          wrapped = true;
        };
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "process.path";
          data = "/nix/store/aaaa-firefox/bin/.firefox-wrapped";
        };
      };
    };
  };

  valueWithPath = {
    expr = {
      foo = {
        package = {
          value = curl;
          path = "/bin/curl";
        };
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "process.path";
          data = "/nix/store/bbbb-curl/bin/curl";
        };
      };
    };
  };

  regexpWithPath = {
    expr = {
      foo = {
        package = {
          regexp = "curl-[0-9]+";
          path = "/bin/curl";
        };
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "process.path";
          data = "$/nix/store/[a-z0-9]{32}-curl-[0-9]+/bin/curl^";
        };
      };
    };
  };

  packageWithOtherConditions = {
    expr = {
      foo = {
        package = firefox;
        port = 443;
        proto = "tcp";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "simple";
              operand = "dest.port";
              data = "443";
            }
            {
              type = "simple";
              operand = "process.path";
              data = "/nix/store/aaaa-firefox/bin/firefox";
            }
            {
              type = "simple";
              operand = "protocol";
              data = "tcp";
            }
          ];
        };
      };
    };
  };

  packageWithProcessPath = {
    expr = {
      foo = {
        package = firefox;
        processPath = "/usr/bin/firefox";
      };
    };
    expectedError.msg = "cannot specify both";
  };

  packageWithProcessPathRegexp = {
    expr = {
      foo = {
        package = firefox;
        processPath.regexp = "/usr/bin/.*";
      };
    };
    expectedError.msg = "cannot specify both";
  };

  wrappedWithPath = {
    expr = {
      foo = {
        package = {
          value = firefox;
          wrapped = true;
          path = "/bin/firefox";
        };
      };
    };
    expectedError.msg = "cannot specify both";
  };

  regexpWithoutPath = {
    expr = {
      foo = {
        package.regexp = "curl-[0-9]+";
      };
    };
    expectedError.msg = "must specify 'path'";
  };

  emptyPackage = {
    expr = {
      foo = {
        package = { };
      };
    };
    expectedError.msg = "must specify either 'value' or 'regexp'";
  };

  wildcardScopeWithPackage = {
    expr = {
      foo = {
        package = {
          value = firefox;
          scope = "wildcard";
        };
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "process.path";
          data = "$/nix/store/[a-z0-9]{32}-firefox-1\\.0/.*^";
        };
      };
    };
  };

  wildcardScopeWithRegexp = {
    expr = {
      foo = {
        package = {
          regexp = "curl-[0-9]+";
          scope = "wildcard";
        };
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "process.path";
          data = "$/nix/store/[a-z0-9]{32}-curl-[0-9]+/.*^";
        };
      };
    };
  };

  wildcardScopeWithPathError = {
    expr = {
      foo = {
        package = {
          value = firefox;
          path = "/bin/firefox";
          scope = "wildcard";
        };
      };
    };
    expectedError.msg = "wildcard scope cannot specify 'path'";
  };

  wildcardScopeWithWrappedError = {
    expr = {
      foo = {
        package = {
          value = firefox;
          wrapped = true;
          scope = "wildcard";
        };
      };
    };
    expectedError.msg = "wildcard scope cannot specify 'wrapped'";
  };
}
