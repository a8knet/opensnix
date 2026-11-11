{
  handWrittenRuleKept = {
    expr = {
      foo = {
        host = "example.com";
      };
    };
    extraModules = [
      (_: {
        config.services.opensnitch.rules."my-own-rule" = {
          name = "my-own-rule";
          action = "deny";
          created = "2026-09-22T00:00:00Z";
          updated = "2026-09-22T00:00:00Z";
          enabled = true;
          duration = "always";
          operator = {
            type = "simple";
            operand = "process.path";
            data = "/bin/bar";
          };
        };
      })
    ];
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "dest.host";
          data = "example.com";
        };
      };
      "my-own-rule" = {
        name = "my-own-rule";
        action = "deny";
        operator = {
          type = "simple";
          operand = "process.path";
          data = "/bin/bar";
        };
      };
    };
    expectedWarnings = [ ];
  };

  handWrittenActionConflictFails = {
    expr = {
      foo = {
        host = "example.com";
      };
    };
    extraModules = [
      (_: {
        config.services.opensnitch.rules."opensnix-foo".action = "deny";
      })
    ];
    expectedError.msg = ".*conflicting definition values.*";
  };

  handWrittenLeafAdded = {
    expr = {
      foo = {
        host = "example.com";
      };
    };
    extraModules = [
      (_: {
        config.services.opensnitch.rules."opensnix-foo".precedence = true;
      })
    ];
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        precedence = true;
        operator = {
          type = "simple";
          operand = "dest.host";
          data = "example.com";
        };
      };
    };
    expectedWarnings = [ "services.opensnitch.rules overrides opensnix-generated rules" ];
  };

  restatedGeneratedRule = {
    expr = {
      foo = {
        host = "example.com";
      };
    };
    extraModules = [
      (_: {
        config.services.opensnitch.rules."opensnix-foo" = {
          name = "opensnix-foo";
          action = "allow";
          created = "2026-09-22T00:00:00Z";
          updated = "2026-09-22T00:00:00Z";
          enabled = true;
          duration = "always";
          operator = {
            type = "simple";
            operand = "dest.host";
            data = "example.com";
          };
        };
      })
    ];
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "dest.host";
          data = "example.com";
        };
      };
    };
    expectedWarnings = [ ];
  };
}
