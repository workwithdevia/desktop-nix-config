{
  time.timeZone = "America/Bogota";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_CO.UTF-8";
    LC_IDENTIFICATION = "es_CO.UTF-8";
    LC_MEASUREMENT = "es_CO.UTF-8";
    LC_MONETARY = "es_CO.UTF-8";
    LC_NAME = "es_CO.UTF-8";
    LC_NUMERIC = "es_CO.UTF-8";
    LC_PAPER = "es_CO.UTF-8";
    LC_TELEPHONE = "es_CO.UTF-8";
    LC_TIME = "es_CO.UTF-8";
  };

  console.keyMap = "es";

  services.keyd = {
    enable = true;

    keyboards.default = {
      ids = ["*"];

      settings = {
        main = {
          capslock = "overload(control, esc)";
          backspace = "noop";

          # Control keys
          leftcontrol = "noop";
          rightcontrol = "noop";

          # Navigation block
          insert = "noop";
          delete = "noop";
          home = "noop";
          end = "noop";
          pageup = "noop";
          pagedown = "noop";

          # Arrow keys
          left = "noop";
          right = "noop";
          up = "noop";
          down = "noop";

          # Function keys
          f1 = "noop";
          f2 = "noop";
          f3 = "noop";
          f4 = "noop";
          f5 = "noop";
          f6 = "noop";
          f7 = "noop";
          f8 = "noop";
          f9 = "noop";
          f10 = "noop";
          f11 = "noop";
          f12 = "noop";

          # Numpad block
          numlock = "noop";
          kp0 = "noop";
          kp1 = "noop";
          kp2 = "noop";
          kp3 = "noop";
          kp4 = "noop";
          kp5 = "noop";
          kp6 = "noop";
          kp7 = "noop";
          kp8 = "noop";
          kp9 = "noop";
          kpdot = "noop";
          kpenter = "noop";
          kpplus = "noop";
          kpminus = "noop";
          kpslash = "noop";
          kpasterisk = "noop";

          # Other keys
          escape = "noop";
        };

        control = {
          # Ctrl + Backspace -> Ctrl + Backspace
          backspace = "C-backspace";
        };

        alt = {
          h = "left";
          j = "down";
          k = "up";
          l = "right";
          i = "insert";
          d = "delete";
          o = "home";
          p = "end";
          n = "pagedown";
          m = "pageup";
        };
      };
    };
  };

  services.xserver.xkb = {
    layout = "es";
    variant = "";
  };
}
