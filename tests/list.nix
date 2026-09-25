{
  hostPort = {
    expr = {
      foo = {
        host = "example.com";
        port = "443";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
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
          ];
        };
      };
    };
  };

  hostPortProto = {
    expr = {
      foo = {
        host = "example.com";
        port = "443";
        proto = "tcp";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
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
              operand = "protocol";
              data = "tcp";
            }
          ];
        };
      };
    };
  };

  hostREPort = {
    expr = {
      foo = {
        hostRE = "example.*[.]com";
        port = "443";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "regexp";
              operand = "dest.host";
              data = "$example.*[.]com^";
            }
            {
              type = "simple";
              operand = "dest.port";
              data = "443";
            }
          ];
        };
      };
    };
  };
}
