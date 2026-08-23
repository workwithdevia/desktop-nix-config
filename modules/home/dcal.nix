{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.dankcalendar.homeModules.dank-calendar
  ];

  programs.dank-calendar = {
    enable = true;
    systemd = {
      enable = true;
      target = "graphical-session.target";
    };
    settings = {
      remindersEnabled = true;
      use24HourClock = true;
      defaultReminderMinutes = 10;
      snoozeMinutes = 5;
    };
  };
}
