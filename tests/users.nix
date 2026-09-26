{
  usersExpansion = {
    expr = {
      foo = {
        users = [
          "bob"
          "alice"
        ];
        host = "example.com";
        port = 443;
      };
    };
    expected = {
      "foo-user-bob" = {
        name = "opensnix-foo-user-bob";
        action = "allow";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "simple";
              operand = "dest.host";
              data = "example.com";
            }
            {
              type = "simple";
              operand = "dest.port";
              data = "443";
            }
            {
              type = "simple";
              operand = "user.name";
              data = "bob";
            }
          ];
        };
      };
      "foo-user-alice" = {
        name = "opensnix-foo-user-alice";
        action = "allow";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "simple";
              operand = "dest.host";
              data = "example.com";
            }
            {
              type = "simple";
              operand = "dest.port";
              data = "443";
            }
            {
              type = "simple";
              operand = "user.name";
              data = "alice";
            }
          ];
        };
      };
    };
  };

  userNamesExpansion = {
    expr = {
      foo = {
        userNames = [ "bob" ];
      };
    };
    expected = {
      "foo-user-bob" = {
        name = "opensnix-foo-user-bob";
        action = "allow";
        operator = {
          type = "simple";
          operand = "user.name";
          data = "bob";
        };
      };
    };
  };

  userIdsExpansion = {
    expr = {
      foo = {
        userIds = [
          1000
          1001
        ];
      };
    };
    expected = {
      "foo-userId-1000" = {
        name = "opensnix-foo-userId-1000";
        action = "allow";
        operator = {
          type = "simple";
          operand = "user.id";
          data = "1000";
        };
      };
      "foo-userId-1001" = {
        name = "opensnix-foo-userId-1001";
        action = "allow";
        operator = {
          type = "simple";
          operand = "user.id";
          data = "1001";
        };
      };
    };
  };

  multipleArrayFieldsError = {
    expr = {
      foo = {
        users = [ "bob" ];
        userIds = [ 1000 ];
      };
    };
    expectedError.msg = "multiple array fields";
  };

  emptyArrayError = {
    expr = {
      foo = {
        users = [ ];
      };
    };
    expectedError.msg = "empty array";
  };

  allowWrapper = {
    expr = {
      foo.allow = {
        users = [ "bob" ];
        host = "example.com";
      };
    };
    expected = {
      "foo-user-bob" = {
        name = "opensnix-foo-user-bob";
        action = "allow";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "simple";
              operand = "dest.host";
              data = "example.com";
            }
            {
              type = "simple";
              operand = "user.name";
              data = "bob";
            }
          ];
        };
      };
    };
  };

  denyWrapper = {
    expr = {
      foo.deny = {
        users = [ "bob" ];
      };
    };
    expected = {
      "foo-user-bob" = {
        name = "opensnix-foo-user-bob";
        action = "deny";
        operator = {
          type = "simple";
          operand = "user.name";
          data = "bob";
        };
      };
    };
  };

  duplicateValuesInArray = {
    expr = {
      foo = {
        users = [
          "bob"
          "bob"
        ];
      };
    };
    expectedError.msg = "duplicate rule name 'foo-user-bob'";
  };

  collisionBetweenRules = {
    expr = {
      "foo-user-bob" = {
        host = "example.com";
      };
      foo = {
        users = [ "bob" ];
      };
    };
    expectedError.msg = "duplicate rule name 'foo-user-bob'";
  };
}
