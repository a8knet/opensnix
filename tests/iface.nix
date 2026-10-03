{
  default = {
    expr = {
      foo = {
        iface = "eth0";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "iface.out";
          data = "eth0";
        };
      };
    };
  };

  "in" = {
    expr = {
      foo = {
        ifaceIn = "eth0";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "iface.in";
          data = "eth0";
        };
      };
    };
  };

  out = {
    expr = {
      foo = {
        ifaceOut = "eth0";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "iface.out";
          data = "eth0";
        };
      };
    };
  };
}
