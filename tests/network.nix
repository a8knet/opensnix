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

  src = {
    expr = {
      foo = {
        srcNetwork = "10.0.0.0/8";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "network";
          operand = "source.network";
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

  aliasSrc = {
    expr = {
      foo = {
        srcNetwork = "LAN";
      };
    };
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "network";
          operand = "source.network";
          data = "LAN";
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

  srcRegexpRejected = {
    expr = {
      foo = {
        srcNetwork.regexp = "10\\..*";
      };
    };
    expectedError.msg = "srcNetwork' is not of type";
  };
}
