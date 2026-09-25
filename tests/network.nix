{
  default = {
    expr = {
      foo = {
        network = "10.0.0.0/8";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "dest.network";
          data = "10.0.0.0/8";
          sensitive = false;
        };
      };
    };
  };

  dst = {
    expr = {
      foo = {
        dstNetwork = "10.0.0.0/8";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "dest.network";
          data = "10.0.0.0/8";
          sensitive = false;
        };
      };
    };
  };

  src = {
    expr = {
      foo = {
        srcNetwork = "10.0.0.0/8";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "source.network";
          data = "10.0.0.0/8";
          sensitive = false;
        };
      };
    };
  };

  re = {
    expr = {
      foo = {
        networkRE = "10\\..*";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "dest.network";
          data = "$10\\..*^";
          sensitive = false;
        };
      };
    };
  };

  dstRe = {
    expr = {
      foo = {
        dstNetworkRE = "10\\..*";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "dest.network";
          data = "$10\\..*^";
          sensitive = false;
        };
      };
    };
  };

  srcRe = {
    expr = {
      foo = {
        srcNetworkRE = "10\\..*";
      };
    };
    expected = {
      foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "source.network";
          data = "$10\\..*^";
          sensitive = false;
        };
      };
    };
  };
}
