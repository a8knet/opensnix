{
  default = {
    expr = {
      foo = {
        network = "10.0.0.0/8";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "network";
          operand = "dest.network";
          data = "10.0.0.0/8";
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
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "network";
          operand = "dest.network";
          data = "10.0.0.0/8";
        };
      };
    };
  };

  aliasLan = {
    expr = {
      foo = {
        network = "LAN";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "network";
          operand = "dest.network";
          data = "LAN";
        };
      };
    };
  };

  aliasMulticast = {
    expr = {
      foo = {
        dstNetwork = "MULTICAST";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "network";
          operand = "dest.network";
          data = "MULTICAST";
        };
      };
    };
  };

  regexpRejected = {
    expr = {
      foo = {
        network.regexp = "10\\..*";
      };
    };
    expectedError.msg = "network' is not of type";
  };

  dstRegexpRejected = {
    expr = {
      foo = {
        dstNetwork.regexp = "10\\..*";
      };
    };
    expectedError.msg = "dstNetwork' is not of type";
  };
}
