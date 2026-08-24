# Perfil: común — Home Manager compartido entre todos los hosts
{config, ...}: {
  imports = [
    ../home
    ../home/packages
    ../home/desktop
  ];

  # Mismo origen de clave que la capa NixOS (hosts/<host>/secrets.yaml):
  # la clave privada se deriva de la host key ed25519 vía ssh-to-age.
  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
}
