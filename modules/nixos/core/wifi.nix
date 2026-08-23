# Red WiFi declarativa del portátil (pc-portatil) basada en wpa_supplicant.
# Las credenciales de las redes se resuelven desde el secreto sops-nix
# `wifi/networks` (en secrets/<host>.yaml). El escritorio conecta por cable.
# Esto reemplaza al antiguo `networking.networkmanager` para evitar tener dos
# gestores inalámbricos en conflicto (wpa_supplicant + NetworkManager).
{config, ...}: {
  networking.wireless = {
    enable = true;
    secretsFile = config.sops.secrets."wifi/networks".path;
  };
}
