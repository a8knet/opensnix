let
  mkMockPkg =
    {
      pname,
      outPath,
      mainProgram ? pname,
      name ? "${pname}-1.0",
    }:
    {
      type = "derivation";
      inherit outPath pname name;
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

  libreoffice = mkMockPkg {
    pname = "libreoffice";
    outPath = "/nix/store/cccc-libreoffice-25.8.5.2-wrapped";
    name = "libreoffice-25.8.5.2-wrapped";
    mainProgram = "soffice";
  };

  wayfire = mkMockPkg {
    pname = "wayfire-wrapped";
    outPath = "/nix/store/dddd-wayfire-wrapped-0.8.1";
    name = "wayfire-wrapped-0.8.1";
    mainProgram = "wayfire";
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
      opensnix-foo = {
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
      opensnix-foo = {
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
      opensnix-foo = {
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
      opensnix-foo = {
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
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "process.path";
          data = "^/nix/store/[a-z0-9]{32}-curl-[0-9]+/bin/curl$";
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
      opensnix-foo = {
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
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "process.path";
          data = "^/nix/store/[a-z0-9]{32}-firefox-1\\.0/.*$";
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
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "process.path";
          data = "^/nix/store/[a-z0-9]{32}-curl-[0-9]+/.*$";
        };
      };
    };
  };

  wildcardScopeStripsWrappedSuffix = {
    expr = {
      foo = {
        package = {
          value = libreoffice;
          scope = "wildcard";
        };
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "process.path";
          data = "^/nix/store/[a-z0-9]{32}-libreoffice-25\\.8\\.5\\.2/.*$";
        };
      };
    };
  };

  wildcardScopeKeepsNonSuffixWrapped = {
    expr = {
      foo = {
        package = {
          value = wayfire;
          scope = "wildcard";
        };
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "process.path";
          data = "^/nix/store/[a-z0-9]{32}-wayfire-wrapped-0\\.8\\.1/.*$";
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
