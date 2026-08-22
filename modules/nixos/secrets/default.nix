# Perfil: secrets — Gestión de secretos cifrados con sops-nix (AGE encryption)
# Los secretos se definen en secrets/<hostname>.yaml y se descifran automáticamente
# al hacer nixos-rebuild. Se exponen como archivos o variables de entorno.
{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [inputs.sops-nix.nixosModules.sops];

  sops = {
    defaultSopsFile = ../../../secrets/${config.networking.hostName}.yaml;
    age = {
      generateKey = true;
      keyFile = "/var/lib/sops/age-key";
      sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    };
    secrets = {
      # rclone → archivo de configuración que lee el servicio rclone-google-drive
      "rclone/config" = {
        path = "/home/workwithdevia/.config/rclone/rclone.conf";
        owner = "workwithdevia";
        group = "users";
        mode = "0600";
      };
      # WiFi → redes inalámbricas para wpa_supplicant (pc-portatil)
      "wifi/networks" = {
        owner = "root";
        group = "root";
        mode = "0600";
      };
      # Notion → API key como variable de entorno para scripts y herramientas CLI
      "notion/api_key" = {
        owner = "workwithdevia";
        group = "users";
        mode = "0400";
      };
      # GitLab Runner → registration token para CI/CD local (pc-wwd)
      "gitlab/runner_token" = {
        owner = "gitlab-runner";
        group = "gitlab-runner";
        mode = "0400";
      };
      # dcal → credenciales OAuth de Google (dankcal) para el calendario
      "dankcal/google_client_id" = {
        owner = "workwithdevia";
        group = "users";
        mode = "0400";
      };
      "dankcal/google_client_secret" = {
        owner = "workwithdevia";
        group = "users";
        mode = "0400";
      };
    };
  };

  # Inyectar secrets como variables de entorno para shells y servicios systemd
  environment.etc."profile.d/secrets.sh" = {
    text = ''
      # Variables de entorno desde sops-nix secrets
      # Notion
      if [ -f "${
        config.sops.secrets."notion/api_key".path
      }" ]; then
        export NOTION_API_KEY="$(cat ${
        config.sops.secrets."notion/api_key".path
      })"
      fi
      # dcal (DankCalendar) — cliente OAuth propio (DANKCAL_GOOGLE_CLIENT_ID/SECRET)
      if [ -f "${
        config.sops.secrets."dankcal/google_client_id".path
      }" ]; then
        export DANKCAL_GOOGLE_CLIENT_ID="$(cat ${
        config.sops.secrets."dankcal/google_client_id".path
      })"
      fi
      if [ -f "${
        config.sops.secrets."dankcal/google_client_secret".path
      }" ]; then
        export DANKCAL_GOOGLE_CLIENT_SECRET="$(cat ${
        config.sops.secrets."dankcal/google_client_secret".path
      })"
      fi
    '';
    mode = "0644";
  };

  # Variables de entorno a nivel de usuario (accesibles por DMS y systemd services)
  home-manager.users.workwithdevia = {
    home.sessionVariables = {
      NOTION_API_KEY = "$(cat ${config.sops.secrets."notion/api_key".path})";
      DANKCAL_GOOGLE_CLIENT_ID = "$(cat ${config.sops.secrets."dankcal/google_client_id".path})";
      DANKCAL_GOOGLE_CLIENT_SECRET = "$(cat ${config.sops.secrets."dankcal/google_client_secret".path})";
    };
  };
}
