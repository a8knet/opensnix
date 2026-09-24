{ opensnixLib }:
let
  inherit (opensnixLib) mkRules;

  # Timestamp used in every test expectation.
  ts = "2026-09-22T00:00:00.000000000+00:00";

  defaultAction = "allow";

  run =
    rules:
    mkRules {
      inherit defaultAction;
      timestamp = ts;
      inherit rules;
    };

  expectedSimple = {
    created = ts;
    updated = ts;
    name = "opensnix-foo";
    enabled = true;
    duration = "always";
    action = "allow";
    operator = {
      type = "simple";
      operand = "dest.host";
      data = "example.com";
      sensitive = false;
    };
  };
in
{
  testDefaultActionAllow = {
    expr = run {
      foo = {
        operator = {
          type = "simple";
          operand = "dest.host";
          data = "example.com";
          sensitive = false;
        };
      };
    };
    expected = {
      foo = expectedSimple;
    };
  };

  testSubkeyAllow = {
    expr = run {
      bar.allow = {
        operator = {
          type = "simple";
        };
      };
    };
    expected = {
      bar = expectedSimple // {
        name = "opensnix-bar";
        action = "allow";
        operator = {
          type = "simple";
        };
      };
    };
  };

  testSubkeyDeny = {
    expr = run {
      baz.deny = {
        operator = {
          type = "simple";
        };
      };
    };
    expected = {
      baz = expectedSimple // {
        name = "opensnix-baz";
        action = "deny";
        operator = {
          type = "simple";
        };
      };
    };
  };

  testDefaultActionDeny = {
    expr = mkRules {
      defaultAction = "deny";
      timestamp = ts;
      rules = {
        foo = {
          operator = {
            type = "simple";
          };
        };
      };
    };
    expected = {
      foo = expectedSimple // {
        action = "deny";
        operator = {
          type = "simple";
        };
      };
    };
  };

  testPassthrough = {
    expr = run {
      foo = {
        precedence = false;
        operator = {
          type = "simple";
        };
      };
    };
    expected = {
      foo = expectedSimple // {
        precedence = false;
        operator = {
          type = "simple";
        };
      };
    };
  };

  testFixedOverride = {
    expr = run {
      foo = {
        name = "user-set-name";
        action = "deny";
        enabled = false;
        operator = {
          type = "simple";
        };
      };
    };
    expected = {
      foo = expectedSimple // {
        operator = {
          type = "simple";
        };
      };
    };
  };
}
