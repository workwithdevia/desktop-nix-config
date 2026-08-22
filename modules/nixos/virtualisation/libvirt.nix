{
  # Habilita el demonio de virtualización
  virtualisation.libvirtd.enable = true;

  # Permisos sin contraseña para iniciar/detener libvirtd on-demand
  security.sudo.extraRules = [
    {
      users = ["workwithdevia"];
      commands = [
        {
          command = "/run/current-system/sw/bin/systemctl start libvirtd";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/systemctl stop libvirtd";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}
