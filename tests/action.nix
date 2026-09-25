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
          sensitive = false;
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
          sensitive = false;
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
          sensitive = false;
        };
      };
    };
  };
}
