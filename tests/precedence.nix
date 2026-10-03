{
  bareTrue = {
    expr = {
      foo = {
        host = "example.com";
        precedence = true;
      };
    };
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
  };

  explicitFalse = {
    expr = {
      foo = {
        host = "example.com";
        precedence = false;
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        precedence = false;
        operator = {
          type = "simple";
          operand = "dest.host";
          data = "example.com";
        };
      };
    };
  };

  allowWrapper = {
    expr = {
      foo = {
        allow = {
          host = "example.com";
        };
        precedence = true;
      };
    };
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
  };

  denyWrapper = {
    expr = {
      foo = {
        deny = {
          host = "example.com";
        };
        precedence = true;
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "deny";
        precedence = true;
        operator = {
          type = "simple";
          operand = "dest.host";
          data = "example.com";
        };
      };
    };
  };

  omittedByDefault = {
    expr = {
      foo = {
        host = "example.com";
      };
    };
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
  };

  arrayExpansionInherits = {
    expr = {
      foo = {
        users = [
          "bob"
          "alice"
        ];
        precedence = true;
      };
    };
    expected = {
      opensnix-foo-user-bob = {
        name = "opensnix-foo-user-bob";
        action = "allow";
        precedence = true;
        operator = {
          type = "simple";
          operand = "user.name";
          data = "bob";
        };
      };
      opensnix-foo-user-alice = {
        name = "opensnix-foo-user-alice";
        action = "allow";
        precedence = true;
        operator = {
          type = "simple";
          operand = "user.name";
          data = "alice";
        };
      };
    };
  };

  badType = {
    expr = {
      foo = {
        host = "example.com";
        precedence = "yes";
      };
    };
    expectedError.msg = "not of type.*null or boolean";
  };
}
