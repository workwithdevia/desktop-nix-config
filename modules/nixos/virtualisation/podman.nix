{
  virtualisation.podman = {
    enable = true;

    # Crea un alias en el sistema para que el comando 'docker' ejecute 'podman'
    dockerCompat = true;

    # Habilita la resolución de nombres DNS entre contenedores (muy útil para podman-compose)
    defaultNetwork.settings.dns_enabled = true;

    # Habilita la red por defecto de podman (podman network create podman)
    defaultNetwork.enable = true;
  };
}
