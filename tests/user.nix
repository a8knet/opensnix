{
  name = {
    expr = {
      foo = {
        userName = "aUser";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "user.name";
          data = "aUser";
          sensitive = false;
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
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "user.name";
          data = "aUser";
          sensitive = false;
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
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "user.id";
          data = "1234";
          sensitive = false;
        };
      };
    };
  };
}
