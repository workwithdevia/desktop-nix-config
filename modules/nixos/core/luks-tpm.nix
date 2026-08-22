# Perfil: luks-tpm — Encriptación de disco con TPM2 auto-unlock (portátiles)
# Solo se activa si isLaptop = true
{
  config,
  lib,
  isLaptop,
  ...
}: {
  boot.initrd.systemd = lib.mkIf isLaptop {
    enable = true;
    emergencyAccess = true;
  };

  # Nota: La configuración de crypttab requiere ejecutar post-instalación:
  # $ sudo systemd-cryptenroll --tpm2-device=auto /dev/<root-partition>
  # Esto vincula LUKS al TPM2 para desbloqueo automático sin PIN.
}
