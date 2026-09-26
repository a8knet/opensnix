{
  allow = {
    expr = {
      bar.allow = {
        port = 123;
      };
    };
    expected = {
      bar = {
        name = "opensnix-bar";
        action = "allow";
        operator = {
          type = "simple";
          operand = "dest.port";
          data = "123";
        };
      };
    };
  };

  deny = {
    expr = {
      baz.deny = {
        user = "aUser";
      };
    };
    expected = {
      baz = {
        name = "opensnix-baz";
        action = "deny";
        operator = {
          type = "simple";
          operand = "user.name";
          data = "aUser";
        };
      };
    };
  };

  defaultDeny = {
    defaultAction = "deny";
    expr = {
      foo = {
        host = "example.com";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "deny";
        operator = {
          type = "simple";
          operand = "dest.host";
          data = "example.com";
        };
      };
    };
  };

  badEnum = {
    expr = {
      foo = {
        host = "example.com";
      };
    };
    defaultAction = "reject";
    expectedError.msg = "defaultAction";
  };

  allowAndDeny = {
    expr = {
      foo = {
        allow = {
          port = 123;
        };
        deny = {
          user = "x";
        };
      };
    };
    expectedError.msg = "cannot specify both";
  };

  unknownKey = {
    expr = {
      foo = {
        bogus = "x";
      };
    };
    expectedError.msg = "bogus";
  };

  emptyFragment = {
    expr = {
      foo = { };
    };
    expectedError.msg = "must contain at least one condition";
  };
}
