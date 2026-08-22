{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # IMPORTANTE: Cambia esto por tu dispositivo real
        # (ej. "/dev/sda" para discos SATA o "/dev/nvme0n1" si es NVMe)
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            # Partición de arranque BIOS (para compatibilidad legacy/GPT)
            bios = {
              size = "1M";
              type = "EF02";
            };
            # Partición EFI /boot en vfat
            esp = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["fmask=0077" "dmask=0077"];
              };
            };
            # Partición Swap (puedes ajustar el tamaño, ej. "4G" u "8G")
            swap = {
              size = "4G";
              content = {
                type = "swap";
                resumeDevice = true; # Opcional: útil si usas hibernación
              };
            };
            # Partición Raíz (ext4) abarcando el resto del espacio
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
