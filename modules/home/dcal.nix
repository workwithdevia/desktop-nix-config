# dcal (DankCalendar) — configuración a nivel de usuario.
# Paquete + servicio systemd vienen del módulo oficial `dank-calendar`
# (inputs.dankcalendar.homeModules.dank-calendar).
# Las credenciales OAuth de Google (secrets dankcal/google_client_id y
# dankcal/google_client_secret) se inyectan al daemon desde sops-nix
# (ver modules/nixos/secrets/default.nix) vía DANKCAL_GOOGLE_CLIENT_ID/SECRET.
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

  # Inyectar el cliente OAuth propio (de sops) al daemon dcal
  systemd.user.services.dcal = {
    Service = {
      ExecStart = lib.mkForce (pkgs.writeShellScript "dcal-with-oauth" ''
        export DANKCAL_GOOGLE_CLIENT_ID="$(cat /run/secrets/dankcal/google_client_id 2>/dev/null)"
        export DANKCAL_GOOGLE_CLIENT_SECRET="$(cat /run/secrets/dankcal/google_client_secret 2>/dev/null)"
        exec ${lib.getExe config.programs.dank-calendar.package} run --session --hidden
      '');
    };
  };
}
