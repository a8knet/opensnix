{
  ports = {
    expr = {
      foo = {
        ports = [
          80
          443
          8080
        ];
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "dest.port";
          data = "^(?:80|443|8080)$";
        };
      };
    };
  };

  dstPorts = {
    expr = {
      foo = {
        dstPorts = [
          80
          443
        ];
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "dest.port";
          data = "^(?:80|443)$";
        };
      };
    };
  };

  srcPorts = {
    expr = {
      foo = {
        srcPorts = [
          1024
          2048
        ];
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "source.port";
          data = "^(?:1024|2048)$";
        };
      };
    };
  };

  singleElement = {
    expr = {
      foo = {
        ports = [ 80 ];
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "dest.port";
          data = "^(?:80)$";
        };
      };
    };
  };

  emptyError = {
    expr = {
      foo = {
        ports = [ ];
      };
    };
    expectedError.msg = "empty list for 'ports'";
  };

  badType = {
    expr = {
      foo = {
        ports = [ "80" ];
      };
    };
    expectedError.msg = "not of type.*signed integer";
  };
}
