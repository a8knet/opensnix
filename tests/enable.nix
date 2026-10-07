{
  rendersWhenServiceEnabled = {
    expr = {
      foo.allow = {
        port = 123;
      };
    };
    expectedWarnings = [ ];
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "dest.port";
          data = "123";
        };
      };
    };
  };

  warnsWhenServiceDisabled = {
    expr = {
      foo.allow = {
        port = 123;
      };
    };
    opensnitchServiceEnable = false;
    expectedWarnings = [
      "services.opensnitch.enable is false"
    ];
    expected = {
      opensnix-foo = {
        name = "opensnix-foo";
        action = "allow";
        operator = {
          type = "simple";
          operand = "dest.port";
          data = "123";
        };
      };
    };
  };

  warnsWhenServiceDisabledWithoutRules = {
    expr = { };
    opensnitchServiceEnable = false;
    expectedWarnings = [
      "services.opensnitch.enable is false"
    ];
    expected = { };
  };
}
