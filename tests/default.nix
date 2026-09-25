{ opensnixLib }:
let
  inherit (opensnixLib) mkRules;

  # Timestamp used in every test expectation.
  ts = "2026-09-22T00:00:00.000000000+00:00";

  defaultAction = "allow";

  run =
    rules:
    mkRules {
      inherit defaultAction;
      timestamp = ts;
      inherit rules;
    };

  # Common, internally-managed fields for every emitted rule.
  base = {
    created = ts;
    updated = ts;
    enabled = true;
    duration = "always";
  };

  # Build the expected full rule for the given name/action/operator.
  expected =
    name: action: operator:
    base
    // {
      name = "opensnix-${name}";
      inherit action;
      inherit operator;
    };

  # Build an expected operator.
  op = type: operand: data: {
    inherit type operand data;
    sensitive = false;
  };
in
{
  testHost = {
    expr = run {
      foo = {
        host = "example.com";
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "simple" "dest.host" "example.com");
    };
  };

  testHostRE = {
    expr = run {
      foo = {
        hostRE = "example.*[.]com";
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "regexp" "dest.host" "$example.*[.]com^");
    };
  };

  testPort = {
    expr = run {
      foo = {
        port = 123;
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "simple" "dest.port" "123");
    };
  };

  testDstPort = {
    expr = run {
      foo = {
        dstPort = 123;
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "simple" "dest.port" "123");
    };
  };

  testSrcPort = {
    expr = run {
      foo = {
        srcPort = 123;
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "simple" "source.port" "123");
    };
  };

  testUserName = {
    expr = run {
      foo = {
        userName = "aUser";
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "simple" "user.name" "aUser");
    };
  };

  testUser = {
    expr = run {
      foo = {
        user = "aUser";
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "simple" "user.name" "aUser");
    };
  };

  testUserId = {
    expr = run {
      foo = {
        userId = 1234;
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "simple" "user.id" "1234");
    };
  };

  testIp = {
    expr = run {
      foo = {
        ip = "1.2.3.4";
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "simple" "dest.ip" "1.2.3.4");
    };
  };

  testDstIp = {
    expr = run {
      foo = {
        dstIp = "1.2.3.4";
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "simple" "dest.ip" "1.2.3.4");
    };
  };

  testSrcIp = {
    expr = run {
      foo = {
        srcIp = "1.2.3.4";
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "simple" "source.ip" "1.2.3.4");
    };
  };

  testNetwork = {
    expr = run {
      foo = {
        network = "10.0.0.0/8";
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "simple" "dest.network" "10.0.0.0/8");
    };
  };

  testDstNetwork = {
    expr = run {
      foo = {
        dstNetwork = "10.0.0.0/8";
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "simple" "dest.network" "10.0.0.0/8");
    };
  };

  testSrcNetwork = {
    expr = run {
      foo = {
        srcNetwork = "10.0.0.0/8";
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "simple" "source.network" "10.0.0.0/8");
    };
  };

  testIpRE = {
    expr = run {
      foo = {
        ipRE = "192\\.168\\..*";
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "regexp" "dest.ip" "$192\\.168\\..*^");
    };
  };

  testDstIpRE = {
    expr = run {
      foo = {
        dstIpRE = "192\\.168\\..*";
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "regexp" "dest.ip" "$192\\.168\\..*^");
    };
  };

  testSrcIpRE = {
    expr = run {
      foo = {
        srcIpRE = "192\\.168\\..*";
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "regexp" "source.ip" "$192\\.168\\..*^");
    };
  };

  testNetworkRE = {
    expr = run {
      foo = {
        networkRE = "10\\..*";
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "regexp" "dest.network" "$10\\..*^");
    };
  };

  testDstNetworkRE = {
    expr = run {
      foo = {
        dstNetworkRE = "10\\..*";
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "regexp" "dest.network" "$10\\..*^");
    };
  };

  testSrcNetworkRE = {
    expr = run {
      foo = {
        srcNetworkRE = "10\\..*";
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "regexp" "source.network" "$10\\..*^");
    };
  };

  testProto = {
    expr = run {
      foo = {
        proto = "tcp";
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "simple" "protocol" "tcp");
    };
  };

  testIface = {
    expr = run {
      foo = {
        iface = "eth0";
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "simple" "iface.out" "eth0");
    };
  };

  testIfaceIn = {
    expr = run {
      foo = {
        ifaceIn = "eth0";
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "simple" "iface.in" "eth0");
    };
  };

  testIfaceOut = {
    expr = run {
      foo = {
        ifaceOut = "eth0";
      };
    };
    expected = {
      foo = expected "foo" "allow" (op "simple" "iface.out" "eth0");
    };
  };

  testSubkeyAllow = {
    expr = run {
      bar.allow = {
        port = 123;
      };
    };
    expected = {
      bar = expected "bar" "allow" (op "simple" "dest.port" "123");
    };
  };

  testSubkeyDeny = {
    expr = run {
      baz.deny = {
        user = "aUser";
      };
    };
    expected = {
      baz = expected "baz" "deny" (op "simple" "user.name" "aUser");
    };
  };

  testDefaultActionDeny = {
    expr = mkRules {
      defaultAction = "deny";
      timestamp = ts;
      rules = {
        foo = {
          host = "example.com";
        };
      };
    };
    expected = {
      foo = expected "foo" "deny" (op "simple" "dest.host" "example.com");
    };
  };
}
