{
  name = {
    expr = {
      foo = {
        userName = "aUser";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "user.name";
          data = "aUser";
        };
      };
    };
  };

  alias = {
    expr = {
      foo = {
        user = "aUser";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "user.name";
          data = "aUser";
        };
      };
    };
  };

  id = {
    expr = {
      foo = {
        userId = 1234;
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "user.id";
          data = "1234";
        };
      };
    };
  };

  badUserIdType = {
    expr = {
      foo = {
        userId = "abc";
      };
    };
    expectedError.msg = "not of type.*signed integer";
  };
}
