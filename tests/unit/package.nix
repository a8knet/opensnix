let
  mkMockPkg = import ./fixtures/mk-mock-pkg.nix;

  firefox = mkMockPkg {
    pname = "firefox";
    outPath = "/nix/store/vk5drhp6vl299ivwrwh2xzj6243g17zz-firefox-1.0";
    mainProgram = "firefox";
  };

  curl = mkMockPkg {
    pname = "curl";
    outPath = "/nix/store/10536wmi6cq4s60qzfiys7w33xjq3hc5-curl-8.22.0";
    name = "curl-8.22.0";
    mainProgram = "curl";
  };

  # Multi-output package: '.name' is the plain derivation name, while the
  # executables live in the separate 'bin' output's store directory.
  curlMulti = mkMockPkg {
    pname = "curl";
    outPath = "/nix/store/1r8bprz4il0w9igbha6pkkfimy4mwkl9-curl-8.22.0";
    binOutPath = "/nix/store/zh52w5abnkfrwhcymwpq4ddx87a6y5g3-curl-8.22.0-bin";
    name = "curl-8.22.0";
    mainProgram = "curl";
  };

  libreoffice = mkMockPkg {
    pname = "libreoffice";
    outPath = "/nix/store/9gnhh4nf3nawl9g6lws14i3vkk5ky4bq-libreoffice-25.8.5.2-wrapped";
    name = "libreoffice-25.8.5.2-wrapped";
    mainProgram = "soffice";
  };

  wayfire = mkMockPkg {
    pname = "wayfire-wrapped";
    outPath = "/nix/store/y3fqx697649kqv1a9c0z1jsk4wy2zlqa-wayfire-wrapped-0.8.1";
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
          data = "/nix/store/vk5drhp6vl299ivwrwh2xzj6243g17zz-firefox-1.0/bin/firefox";
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
          data = "/nix/store/vk5drhp6vl299ivwrwh2xzj6243g17zz-firefox-1.0/bin/firefox";
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
          data = "/nix/store/vk5drhp6vl299ivwrwh2xzj6243g17zz-firefox-1.0/bin/.firefox-wrapped";
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
          data = "/nix/store/10536wmi6cq4s60qzfiys7w33xjq3hc5-curl-8.22.0/bin/curl";
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
          data = "^(?:/nix/store/[0-9abcdfghijklmnpqrsvwxyz]{32}-(?:curl-[0-9]+)/bin/curl)$";
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
              data = "/nix/store/vk5drhp6vl299ivwrwh2xzj6243g17zz-firefox-1.0/bin/firefox";
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
          data = "^(?:/nix/store/[0-9abcdfghijklmnpqrsvwxyz]{32}-(?:firefox-1\\.0)/.*)$";
        };
      };
    };
  };

  # The store directory, not '.name', decides the pattern: curl's executables
  # live in the separate 'bin' output's directory.
  wildcardScopeUsesBinOutput = {
    expr = {
      foo = {
        package = {
          value = curlMulti;
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
          data = "^(?:/nix/store/[0-9abcdfghijklmnpqrsvwxyz]{32}-(?:curl-8\\.22\\.0-bin)/.*)$";
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
          data = "^(?:/nix/store/[0-9abcdfghijklmnpqrsvwxyz]{32}-(?:curl-[0-9]+)/.*)$";
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
          data = "^(?:/nix/store/[0-9abcdfghijklmnpqrsvwxyz]{32}-(?:libreoffice-25\\.8\\.5\\.2)/.*)$";
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
          data = "^(?:/nix/store/[0-9abcdfghijklmnpqrsvwxyz]{32}-(?:wayfire-wrapped-0\\.8\\.1)/.*)$";
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
