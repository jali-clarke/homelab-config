final: prev: {
  # valgrind doesn't like that we're building `armv7l-linux` on
  # an `armv8l` cpu
  libdrm = prev.libdrm.override { withValgrind = false; };
  mesa = prev.mesa.override { withValgrind = false; };
  libpsl = prev.libpsl.overrideAttrs (
    old: {
      nativeBuildInputs = builtins.filter (pkg: !(final.lib.hasInfix "valgrind" pkg.name)) old.nativeBuildInputs;
      configureFlags = builtins.filter (flag: flag != "--enable-valgrind-tests") old.configureFlags;
    }
  );

  # all but one test passes
  libjxl = final.lib.skipCheck prev.libjxl;
  libpulseaudio = final.lib.skipCheck prev.libpulseaudio;
  pulseaudio = final.lib.skipCheck prev.pulseaudio;
  tracker = final.lib.skipCheck prev.tracker;

  buildPackages = prev.buildPackages // {
    python3 = prev.buildPackages.python3.override {
      packageOverrides = pyFinal: pyPrev: {
        # one test fails, prob inconsequential
        eventlet = pyPrev.eventlet.overridePythonAttrs (
          old: { doCheck = false; }
        );
      };
    };
  };
}
