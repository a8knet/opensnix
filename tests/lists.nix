{
  domains-content = {
    expr = {
      foo = {
        domains = [
          "example.com"
          "example.org"
        ];
      };
    };
    expected = {
      foo = {
        action = "allow";
        name = "opensnix-foo";
        operator = {
          type = "lists";
          operand = "lists.domains";
          data = {
            name = "domains.list";
            content = ''
              0.0.0.0 example.com
              0.0.0.0 example.org'';
          };
        };
      };
    };
  };

  hosts-alias-content = {
    expr = {
      foo = {
        hosts = [ "example.com" ];
      };
    };
    expected = {
      foo = {
        action = "allow";
        name = "opensnix-foo";
        operator = {
          type = "lists";
          operand = "lists.domains";
          data = {
            name = "domains.list";
            content = "0.0.0.0 example.com";
          };
        };
      };
    };
  };

  domains-with-other-conditions-structure = {
    expr = {
      foo = {
        domains = [ "example.com" ];
        host = "other.com";
      };
    };
    expected = {
      foo = {
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
              data = "other.com";
            }
          ];
        };
      };
    };
  };

  domains-empty-error = {
    expr = {
      foo = {
        domains = [ ];
      };
    };
    expectedError.msg = "empty list for 'domains'";
  };

  domainsRegexp-content = {
    expr = {
      foo = {
        domains.regexp = [
          ".*example[.]com"
          "sub[.]example[.]org"
        ];
      };
    };
    expected = {
      foo = {
        action = "allow";
        name = "opensnix-foo";
        operator = {
          type = "lists";
          operand = "lists.domains_regexp";
          data = {
            name = "domains_regexp.list";
            content = ''
              ^.*example[.]com$
              ^sub[.]example[.]org$'';
          };
        };
      };
    };
  };

  hostsRegexp-alias-content = {
    expr = {
      foo = {
        hosts.regexp = [ ".*example[.]com" ];
      };
    };
    expected = {
      foo = {
        action = "allow";
        name = "opensnix-foo";
        operator = {
          type = "lists";
          operand = "lists.domains_regexp";
          data = {
            name = "domains_regexp.list";
            content = "^.*example[.]com$";
          };
        };
      };
    };
  };

  domainsRegexp-empty-error = {
    expr = {
      foo = {
        domains.regexp = [ ];
      };
    };
    expectedError.msg = "empty list for 'domains'";
  };

  domainsRegexp-withCaret = {
    expr = {
      foo = {
        domains.regexp = [ "^example.com" ];
      };
    };
    expectedError.msg = "string without leading";
  };

  hostsRegexp-withDollar = {
    expr = {
      foo = {
        hosts.regexp = [ "example.com$" ];
      };
    };
    expectedError.msg = "trailing";
  };

  ips-content = {
    expr = {
      foo = {
        ips = [
          "192.168.1.1"
          "10.0.0.1"
          "8.8.8.8"
        ];
      };
    };
    expected = {
      foo = {
        action = "allow";
        name = "opensnix-foo";
        operator = {
          type = "lists";
          operand = "lists.ips";
          data = {
            name = "ips.list";
            content = ''
              192.168.1.1
              10.0.0.1
              8.8.8.8'';
          };
        };
      };
    };
  };

  ips-with-other-conditions = {
    expr = {
      foo = {
        ips = [ "192.168.1.1" ];
        host = "example.com";
      };
    };
    expected = {
      foo = {
        action = "allow";
        name = "opensnix-foo";
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
              type = "lists";
              operand = "lists.ips";
              data = {
                name = "ips.list";
                content = "192.168.1.1";
              };
            }
          ];
        };
      };
    };
  };

  ips-empty-error = {
    expr = {
      foo = {
        ips = [ ];
      };
    };
    expectedError.msg = "empty list for 'ips'";
  };

  nets-content = {
    expr = {
      foo = {
        nets = [
          "192.168.1.0/24"
          "10.0.0.0/8"
        ];
      };
    };
    expected = {
      foo = {
        action = "allow";
        name = "opensnix-foo";
        operator = {
          type = "lists";
          operand = "lists.nets";
          data = {
            name = "nets.list";
            content = ''
              192.168.1.0/24
              10.0.0.0/8'';
          };
        };
      };
    };
  };

  nets-with-other-conditions = {
    expr = {
      foo = {
        nets = [ "192.168.1.0/24" ];
        host = "example.com";
      };
    };
    expected = {
      foo = {
        action = "allow";
        name = "opensnix-foo";
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
              type = "lists";
              operand = "lists.nets";
              data = {
                name = "nets.list";
                content = "192.168.1.0/24";
              };
            }
          ];
        };
      };
    };
  };

  nets-empty-error = {
    expr = {
      foo = {
        nets = [ ];
      };
    };
    expectedError.msg = "empty list for 'nets'";
  };

  domains-deny = {
    defaultAction = "deny";
    expr = {
      foo = {
        domains = [ "example.com" ];
      };
    };
    expected = {
      foo = {
        action = "deny";
        name = "opensnix-foo";
        operator = {
          type = "lists";
          operand = "lists.domains";
          data = {
            name = "domains.list";
            content = "0.0.0.0 example.com";
          };
        };
      };
    };
  };

  multiple-list-operands = {
    expr = {
      foo = {
        domains = [ "example.com" ];
        ips = [ "192.168.1.1" ];
        nets = [ "10.0.0.0/8" ];
      };
    };
    expected = {
      foo = {
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
              operand = "lists.ips";
              data = {
                name = "ips.list";
                content = "192.168.1.1";
              };
            }
            {
              type = "lists";
              operand = "lists.nets";
              data = {
                name = "nets.list";
                content = "10.0.0.0/8";
              };
            }
          ];
        };
      };
    };
  };
}
