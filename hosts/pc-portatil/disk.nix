{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # IMPORTANTE: Cambia esto por tu dispositivo real
        # (ej. "/dev/nvme0n1" si es NVMe, o "/dev/sda" si es SATA)
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            # Partición de arranque BIOS (opcional pero recomendada para compatibilidad)
            bios = {
              size = "1M";
              type = "EF02";
            };
            # Partición EFI para el bootloader
            esp = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };
            # Partición Raíz en ext4 (coincidiendo con tu hardware-configuration)
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
