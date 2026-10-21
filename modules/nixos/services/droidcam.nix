{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.droidcam-client;
in {
  options.services.droidcam-client = {
    enable = lib.mkEnableOption "Servicio local de DroidCam CLI (auto-conexión)";

    ip = lib.mkOption {
      type = lib.types.str;
      default = "192.168.40.4";
      description = "Dirección IP del teléfono en la red local";
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 4747;
      description = "Puerto de conexión de DroidCam";
    };

    videoDevice = lib.mkOption {
      type = lib.types.str;
      default = "/dev/video0";
      description = "Ruta del dispositivo v4l2loopback";
    };
  };

  config = lib.mkIf cfg.enable {
    # ============================================================
    # KERNEL MODULE & PACKAGES (Nativo de NixOS)
    # ============================================================

    # Esto instala el paquete 'droidcam' y carga 'v4l2loopback' automáticamente
    programs.droidcam.enable = true;

    # ============================================================
    # SYSTEMD SERVICE
    # ============================================================

    systemd.services.droidcam-client = {
      description = "DroidCam CLI Client Auto-Connect";

      # Solo intentar conectar cuando la red esté disponible
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";

        # Opcional: Ejecutar como tu usuario de escritorio
        # User = "workwithdevia";

        # Ejecuta el cliente CLI inyectando las variables de las opciones
        ExecStart = "${pkgs.droidcam}/bin/droidcam-cli -video ${cfg.ip} ${toString cfg.port}";

        # Reiniciar si se pierde la conexión con el teléfono
        Restart = "always";
        RestartSec = "10s";
        TimeoutStopSec = "15s";
      };
    };
  };
}
