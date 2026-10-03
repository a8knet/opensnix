{
  groupSharedUserName = {
    expr = {
      systemd = {
        userName = "systemd-resolve";
        rules = {
          dns = {
            network = "LAN";
            port = 53;
          };
        };
      };
    };
    expected = {
      opensnix-systemd-dns = {
        name = "opensnix-systemd-dns";
        action = "allow";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "network";
              operand = "dest.network";
              data = "LAN";
            }
            {
              type = "simple";
              operand = "dest.port";
              data = "53";
            }
            {
              type = "simple";
              operand = "user.name";
              data = "systemd-resolve";
            }
          ];
        };
      };
    };
  };

  groupPackageRegexp = {
    expr = {
      systemd-resolved = {
        userName = "systemd-resolve";
        package = {
          regexp = "systemd-[0-9]+[.][0-9]+";
          path = "/lib/systemd/systemd-resolved";
        };
        rules = {
          dns = {
            network = "LAN";
            port = 53;
          };
          multicast = {
            network = "MULTICAST";
            ports = [
              5353
              5355
            ];
          };
        };
      };
    };
    expected = {
      opensnix-systemd-resolved-dns = {
        name = "opensnix-systemd-resolved-dns";
        action = "allow";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "network";
              operand = "dest.network";
              data = "LAN";
            }
            {
              type = "simple";
              operand = "dest.port";
              data = "53";
            }
            {
              type = "regexp";
              operand = "process.path";
              data = "^/nix/store/[a-z0-9]{32}-systemd-[0-9]+[.][0-9]+/lib/systemd/systemd-resolved$";
            }
            {
              type = "simple";
              operand = "user.name";
              data = "systemd-resolve";
            }
          ];
        };
      };
      opensnix-systemd-resolved-multicast = {
        name = "opensnix-systemd-resolved-multicast";
        action = "allow";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "network";
              operand = "dest.network";
              data = "MULTICAST";
            }
            {
              type = "regexp";
              operand = "dest.port";
              data = "^(?:5353|5355)$";
            }
            {
              type = "regexp";
              operand = "process.path";
              data = "^/nix/store/[a-z0-9]{32}-systemd-[0-9]+[.][0-9]+/lib/systemd/systemd-resolved$";
            }
            {
              type = "simple";
              operand = "user.name";
              data = "systemd-resolve";
            }
          ];
        };
      };
    };
  };

  groupActionInheritance = {
    expr = {
      desktop = {
        allow.userName = "alice";
        rules = {
          browse.host = "example.com";
          blocked.deny.host = "evil.example";
        };
      };
    };
    expected = {
      opensnix-desktop-browse = {
        name = "opensnix-desktop-browse";
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
              data = "alice";
            }
          ];
        };
      };
      opensnix-desktop-blocked = {
        name = "opensnix-desktop-blocked";
        action = "deny";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "simple";
              operand = "dest.host";
              data = "evil.example";
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

  groupPrecedenceInheritance = {
    expr = {
      g = {
        precedence = true;
        rules = {
          a.host = "a.example";
          b = {
            precedence = false;
            host = "b.example";
          };
        };
      };
    };
    expected = {
      opensnix-g-a = {
        name = "opensnix-g-a";
        action = "allow";
        precedence = true;
        operator = {
          type = "simple";
          operand = "dest.host";
          data = "a.example";
        };
      };
      opensnix-g-b = {
        name = "opensnix-g-b";
        action = "allow";
        precedence = false;
        operator = {
          type = "simple";
          operand = "dest.host";
          data = "b.example";
        };
      };
    };
  };

  groupChildOverridesCondition = {
    expr = {
      g = {
        port = 53;
        rules.dns.port = 8080;
      };
    };
    expected = {
      opensnix-g-dns = {
        name = "opensnix-g-dns";
        action = "allow";
        operator = {
          type = "simple";
          operand = "dest.port";
          data = "8080";
        };
      };
    };
  };

  groupPackagePartialMerge = {
    expr = {
      foo = {
        package.regexp = "foo-[0-9]+";
        rules.bar.package.path = "/bin/bar";
      };
    };
    expected = {
      opensnix-foo-bar = {
        name = "opensnix-foo-bar";
        action = "allow";
        operator = {
          type = "regexp";
          operand = "process.path";
          data = "^/nix/store/[a-z0-9]{32}-foo-[0-9]+/bin/bar$";
        };
      };
    };
  };

  groupArrayField = {
    expr = {
      shared = {
        users = [
          "bob"
          "alice"
        ];
        rules.web.host = "example.com";
      };
    };
    expected = {
      opensnix-shared-web-user-bob = {
        name = "opensnix-shared-web-user-bob";
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
      opensnix-shared-web-user-alice = {
        name = "opensnix-shared-web-user-alice";
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
              data = "alice";
            }
          ];
        };
      };
    };
  };

  groupEmptyRulesError = {
    expr = {
      g = {
        userName = "alice";
        rules = { };
      };
    };
    expectedError.msg = "empty 'rules' attrset";
  };

  groupChildOverridesUserName = {
    expr = {
      g = {
        userName = "alice";
        rules = {
          asAlice.host = "example.com";
          asBob = {
            userName = "bob";
            host = "other.example";
          };
        };
      };
    };
    expected = {
      opensnix-g-asAlice = {
        name = "opensnix-g-asAlice";
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
              data = "alice";
            }
          ];
        };
      };
      opensnix-g-asBob = {
        name = "opensnix-g-asBob";
        action = "allow";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "simple";
              operand = "dest.host";
              data = "other.example";
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

  nestedThreeLevels = {
    expr = {
      vm = {
        userName = "alice";
        precedence = true;
        rules = {
          web = {
            deny.port = 443;
            rules = {
              api.host = "api.example";
              static.port = 80;
            };
          };
        };
      };
    };
    expected = {
      opensnix-vm-web-api = {
        name = "opensnix-vm-web-api";
        action = "deny";
        precedence = true;
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "simple";
              operand = "dest.host";
              data = "api.example";
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
      opensnix-vm-web-static = {
        name = "opensnix-vm-web-static";
        action = "deny";
        precedence = true;
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "simple";
              operand = "dest.port";
              data = "80";
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

  nestedArrayField = {
    expr = {
      shared = {
        users = [
          "bob"
          "alice"
        ];
        rules.mid.rules.leaf.host = "example.com";
      };
    };
    expected = {
      opensnix-shared-mid-leaf-user-bob = {
        name = "opensnix-shared-mid-leaf-user-bob";
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
      opensnix-shared-mid-leaf-user-alice = {
        name = "opensnix-shared-mid-leaf-user-alice";
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
              data = "alice";
            }
          ];
        };
      };
    };
  };

  nestedUnknownKeyTypeError = {
    expr = {
      g = {
        rules.mid.rules.deep.hso = "typo";
      };
    };
    expectedError.msg = "does not exist";
  };

  nestedEmptyRulesError = {
    expr = {
      g = {
        rules.mid.rules = { };
      };
    };
    expectedError.msg = "empty 'rules' attrset";
  };

  groupChildNameCollision = {
    expr = {
      g-web = {
        host = "other.example";
      };
      g = {
        rules.web.host = "example.com";
      };
    };
    expectedError.msg = "duplicate rule name 'g-web'";
  };
}
