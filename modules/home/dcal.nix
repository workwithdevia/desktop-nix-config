{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: let
  dankcalendarPackage = (inputs.dankcalendar.lib.mkDcal pkgs).overrideAttrs (_: {
    vendorHash = "sha256-0dhVy8BNTRrNo1cFAVlR80yaUMqa2PCNbx4cYl04g9g=";
  });
in {
  imports = [
    inputs.dankcalendar.homeModules.dank-calendar
  ];

  programs.dank-calendar = {
    enable = true;

    package = dankcalendarPackage;

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
