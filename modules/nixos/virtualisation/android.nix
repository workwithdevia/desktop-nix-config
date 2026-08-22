{
  config,
  pkgs,
  ...
}: {
  # Agregamos tu usuario a los grupos necesarios para desarrollo móvil
  # 'adbusers': Permite la conexión y depuración USB con dispositivos físicos
  # 'kvm': Habilita la aceleración por hardware por si decides usar el emulador de Android
  users.users.workwithdevia = {
    extraGroups = [
      "adbusers"
      "kvm"
    ];
  };

  # Instalamos Android Studio a nivel de sistema (incluye el entorno FHS)
  environment.systemPackages = with pkgs; [
    android-studio
    android-tools
  ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      1420
    ];
  };
}
