{
  defaultFromFlakeDate = {
    expr = {
      foo = {
        port = 123;
      };
    };
    useDefaultTimestamp = true;
    lastModifiedDate = "20261002183107";
    expectedTs = "2026-10-02T18:31:07Z";
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

  explicitUtcAccepted = {
    expr = {
      foo = {
        port = 123;
      };
    };
    timestamp = "2026-10-02T18:31:07Z";
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

  flakeDateRejected = {
    expr = {
      foo = {
        port = 123;
      };
    };
    timestamp = "20261002183107";
    expectedError.msg = "not of type.*RFC3339";
  };

  garbageRejected = {
    expr = {
      foo = {
        port = 123;
      };
    };
    timestamp = "yesterday";
    expectedError.msg = "not of type.*RFC3339";
  };

  missingZoneRejected = {
    expr = {
      foo = {
        port = 123;
      };
    };
    timestamp = "2026-10-02T18:31:07";
    expectedError.msg = "not of type.*RFC3339";
  };

  offsetRejected = {
    expr = {
      foo = {
        port = 123;
      };
    };
    timestamp = "2026-10-02T18:31:07+03:00";
    expectedError.msg = "not of type.*RFC3339";
  };

  fractionalRejected = {
    expr = {
      foo = {
        port = 123;
      };
    };
    timestamp = "2026-10-02T18:31:07.123Z";
    expectedError.msg = "not of type.*RFC3339";
  };
}
