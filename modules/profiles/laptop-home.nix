# Perfil: laptop-home — Home Manager extras para pc-portatil (display único eDP-1)
{
  xdg.configFile."sway/config.d/host-displays".text = ''
    # Display Settings para portátil
    output eDP-1 pos 0 0 res 1920x1080
    workspace 1 output eDP-1
  '';
}
