# Alias keys map to the same OpenSnitch operand (hosts/domains, dstPort/
# port, ifaceOut/iface, ...). A rule fragment may set at most one condition
# per operand: the daemon ANDs same-operand children, so such pairs are
# always redundant or unsatisfiable and are rejected at evaluation time.
{
  domains-hosts-collision = {
    expr = {
      foo = {
        domains = [ "example.com" ];
        hosts = [ "example.org" ];
      };
    };
    expectedError.msg = "specifies multiple conditions for operand 'lists.domains'";
  };

  port-dstPort-collision = {
    expr = {
      foo = {
        port = 80;
        dstPort = 443;
      };
    };
    expectedError.msg = "specifies multiple conditions for operand 'dest.port'";
  };

  ports-dstPorts-collision = {
    expr = {
      foo = {
        ports = [
          80
          443
        ];
        dstPorts = [ 8080 ];
      };
    };
    expectedError.msg = "specifies multiple conditions for operand 'dest.port'";
  };

  port-ports-crossForm-collision = {
    expr = {
      foo = {
        port = 53;
        ports = [
          53
          853
        ];
      };
    };
    expectedError.msg = "specifies multiple conditions for operand 'dest.port'";
  };

  srcPort-srcPorts-collision = {
    expr = {
      foo = {
        srcPort = 40000;
        srcPorts = [
          40000
          40001
        ];
      };
    };
    expectedError.msg = "specifies multiple conditions for operand 'source.port'";
  };

  ip-dstIp-collision = {
    expr = {
      foo = {
        ip = "10.0.0.1";
        dstIp = "10.0.0.2";
      };
    };
    expectedError.msg = "specifies multiple conditions for operand 'dest.ip'";
  };

  network-dstNetwork-collision = {
    expr = {
      foo = {
        network = "10.0.0.0/24";
        dstNetwork = "192.168.0.0/24";
      };
    };
    expectedError.msg = "specifies multiple conditions for operand 'dest.network'";
  };

  user-userName-collision = {
    expr = {
      foo = {
        user = "alice";
        userName = "bob";
      };
    };
    expectedError.msg = "specifies multiple conditions for operand 'user.name'";
  };

  iface-ifaceOut-collision = {
    expr = {
      foo = {
        iface = "eth0";
        ifaceOut = "wlan0";
      };
    };
    expectedError.msg = "specifies multiple conditions for operand 'iface.out'";
  };

  usersArray-userName-collision = {
    expr = {
      foo = {
        users = [
          "alice"
          "bob"
        ];
        userName = "carol";
      };
    };
    expectedError.msg = "specifies multiple conditions for operand 'user.name'";
  };

  usersArray-user-collision = {
    expr = {
      foo = {
        users = [ "alice" ];
        user = "bob";
      };
    };
    expectedError.msg = "specifies multiple conditions for operand 'user.name'";
  };

  group-inherited-alias-collision = {
    expr = {
      g = {
        domains = [ "example.com" ];
        rules = {
          c = {
            hosts = [ "example.org" ];
          };
        };
      };
    };
    # The leaf name shows the collision is checked after group inheritance.
    expectedError.msg = "rule 'g-c' specifies multiple conditions for operand 'lists.domains'";
  };

  # Bare lists.domains and regexp lists.domains_regexp are distinct operands,
  # so mixing the subkey forms across the alias pair stays legal.
  domainsBare-hostsRegexp-distinctOperands = {
    expr = {
      foo = {
        domains = [ "example.com" ];
        hosts.regexp = [ ".*example[.]org" ];
      };
    };
    expected = {
      opensnix-foo = {
        action = "allow";
        name = "opensnix-foo";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "lists";
              operand = "lists.domains";
              data = {
                name = "domains.list";
                content = "0.0.0.0 example.com";
              };
            }
            {
              type = "lists";
              operand = "lists.domains_regexp";
              data = {
                name = "domains_regexp.list";
                content = "^(?:.*example[.]org)$";
              };
            }
          ];
        };
      };
    };
  };

  # Different operands never collide: user.name AND user.id is a legitimate
  # narrowing, as is dest.host AND lists.domains.
  user-userId-distinctOperands = {
    expr = {
      foo = {
        user = "alice";
        userId = 1000;
      };
    };
    expected = {
      opensnix-foo = {
        action = "allow";
        name = "opensnix-foo";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "simple";
              operand = "user.name";
              data = "alice";
            }
            {
              type = "simple";
              operand = "user.id";
              data = "1000";
            }
          ];
        };
      };
    };
  };

  host-domains-distinctOperands = {
    expr = {
      foo = {
        host = "api.example.com";
        domains = [ "example.com" ];
      };
    };
    expected = {
      opensnix-foo = {
        action = "allow";
        name = "opensnix-foo";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "lists";
              operand = "lists.domains";
              data = {
                name = "domains.list";
                content = "0.0.0.0 example.com";
              };
            }
            {
              type = "simple";
              operand = "dest.host";
              data = "api.example.com";
            }
          ];
        };
      };
    };
  };
}
