{
  allow = {
    expr = {
      bar.allow = {
        port = 123;
      };
    };
    expected = {
      opensnix-bar = {
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
      opensnix-baz = {
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

  reject = {
    expr = {
      qux.reject = {
        port = 53;
      };
    };
    expected = {
      opensnix-qux = {
        name = "opensnix-qux";
        action = "reject";
        operator = {
          type = "simple";
          operand = "dest.port";
          data = "53";
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
      opensnix-foo = {
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

  defaultReject = {
    defaultAction = "reject";
    expr = {
      foo = {
        host = "example.com";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "reject";
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
    defaultAction = "block";
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
    expectedError.msg = "more than one";
  };

  allowAndReject = {
    expr = {
      foo = {
        allow = {
          port = 123;
        };
        reject = {
          user = "x";
        };
      };
    };
    expectedError.msg = "more than one";
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

  nameWithSlash = {
    expr = {
      "foo/bar" = {
        network = "10.0.0.0/8";
      };
    };
    expectedError.msg = "invalid rule name 'foo/bar'";
  };

  arrayValueWithSlash = {
    expr = {
      foo = {
        users = [ "a/b" ];
      };
    };
    expectedError.msg = "invalid rule name 'foo-user-a/b'";
  };
}
