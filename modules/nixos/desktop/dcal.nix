# dcal — GNOME Keyring para guardar de forma segura las credenciales OAuth (Google, Microsoft)
{
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
}
