{
  pkgs,
  nixpkgs,
  self,
}:
let
  # Eval-time fields (timestamps, enabled, duration) omitted.
  expectedRules = {
    opensnix-block-ssh = {
      action = "deny";
      operator = {
        type = "simple";
        operand = "dest.port";
        data = "22";
      };
    };
    opensnix-curl-exact = {
      action = "allow";
      operator = {
        type = "simple";
        operand = "process.path";
        data = "${pkgs.curl}/bin/curl";
      };
    };
    opensnix-curl-wildcard = {
      operator = {
        type = "regexp";
        operand = "process.path";
      };
    };
    opensnix-hello-wildcard = {
      operator = {
        type = "regexp";
        operand = "process.path";
      };
    };
    opensnix-lan-address = {
      action = "allow";
      operator = {
        type = "network";
        operand = "dest.network";
        data = "10.0.0.0/8";
      };
    };
    opensnix-port-list = {
      action = "allow";
      operator = {
        type = "regexp";
        operand = "dest.port";
        data = "^(?:80|443|8080)$";
      };
    };
    opensnix-reject-c2 = {
      action = "reject";
      operator = {
        type = "simple";
        operand = "dest.port";
        data = "6667";
      };
    };
    opensnix-simple-port = {
      action = "allow";
      operator = {
        type = "simple";
        operand = "dest.port";
        data = "443";
      };
    };
    opensnix-web-and-user = {
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
            data = "root";
          }
        ];
      };
    };
  };

  # Expected JSON travels as a host-side store file; quoting it into the Nix
  # indented string would be fragile.
  expectedFile = pkgs.writeText "expected-rules.json" (builtins.toJSON expectedRules);
in
nixpkgs.lib.nixos.runTest {
  hostPkgs = pkgs;

  name = "smoke";

  nodes.smoke =
    { pkgs, ... }:
    {
      imports = [ self.nixosModules.default ];

      # Avoid a second nftables manager competing with opensnitchd.
      networking.firewall.enable = false;

      services.opensnitch = {
        enable = true;
        # Keep the test independent of eBPF kernel module support.
        settings.ProcMonitorMethod = "proc";
      };

      opensnix = {
        enable = true;

        rules = {
          simple-port.port = 443;
          port-list.ports = [
            80
            443
            8080
          ];
          lan-address.network = "10.0.0.0/8";
          web-and-user = {
            host = "example.com";
            user = "root";
          };
          curl-exact.package = pkgs.curl;
          # curl is multi-output: its executables live in the store directory
          # '<name>-bin', which differs from the derivation name.
          curl-wildcard.package = {
            value = pkgs.curl;
            scope = "wildcard";
          };
          hello-wildcard.package = {
            value = pkgs.hello;
            scope = "wildcard";
          };
          block-ssh.deny = {
            port = 22;
          };
          reject-c2.reject.port = 6667;
        };
      };
    };

  testScript = ''
    import json
    import re

    expected = json.loads(open("${expectedFile}").read())
    rules_dir = "/var/lib/opensnitch/rules"


    def matches(actual, want):
        if isinstance(want, dict):
            return isinstance(actual, dict) and all(
                k in actual and matches(actual[k], v) for k, v in want.items()
            )
        if isinstance(want, list):
            return (
                isinstance(actual, list)
                and len(actual) == len(want)
                and all(matches(a, w) for a, w in zip(actual, want))
            )
        return actual == want


    start_all()
    smoke.wait_for_unit("opensnitchd.service")

    # Nothing missing, nothing extra.
    files = smoke.succeed(f"ls -1 {rules_dir}").split()
    assert sorted(files) == sorted(f"{name}.json" for name in expected), files

    # Every expected rule is deployed as a store symlink and matches the
    # hand-written (sparse) expectation.
    for name, want in expected.items():
        path = f"{rules_dir}/{name}.json"
        smoke.wait_for_file(path)
        smoke.succeed(f"test -L {path}")
        loaded = json.loads(smoke.succeed(f"cat {path}"))
        assert matches(loaded, want), f"rule {name} differs: {loaded}"

    # The wildcard regexps are only checked for type/operand above; additionally
    # verify each is a valid regex that matches its own package's real binary
    # path and not the other one's. curl witnesses the multi-output case: its
    # executables live in '<name>-bin', not in the directory '<name>'.
    for rule, own, other in (
        ("opensnix-hello-wildcard", "${pkgs.lib.getExe pkgs.hello}", "${pkgs.lib.getExe pkgs.curl}"),
        ("opensnix-curl-wildcard", "${pkgs.lib.getExe pkgs.curl}", "${pkgs.lib.getExe pkgs.hello}"),
    ):
        data = json.loads(smoke.succeed(f"cat {rules_dir}/{rule}.json"))["operator"]["data"]
        assert re.fullmatch(data, own), (rule, data)
        assert not re.fullmatch(data, other), (rule, data)

    # Pinned from a live run: the daemon scans the rules directory, and
    # nothing at ERR level or above is logged. Two WAR lines are expected
    # and tolerated: the unconfigured tasks file, and the EBPF-DNS probe,
    # which runs regardless of ProcMonitorMethod=proc.
    journal = smoke.succeed("journalctl -u opensnitchd --no-pager -o cat")
    assert "Loading rules from /var/lib/opensnitch/rules" in journal, journal
    fatal = re.compile(
        r"^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]\s+(EMERG|ALERT|CRIT|FATAL|ERROR|ERR)\b",
        re.MULTILINE,
    )
    assert fatal.search(journal) is None, f"fatal journal line:\n{journal}"
  '';
}
