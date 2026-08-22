# Perfil: desktop-home — Home Manager extras para pc-wwd (rclone, multi-monitor)
{
  services.rclone-google-drive = {
    enable = true;
    mode = "sync";
    remoteName = "gdrive";
    remoteRoot = "Backups";
    interval = "15m";
    directories = {
      Documents = {};
      Music = {};
      Images = {};
    };
  };

  xdg.configFile."sway/config.d/host-displays".text = ''
    # Display Settings para escritorio multi-monitor
    output HDMI-A-2 pos 0 0 res 1920x1080
    output DP-2 pos 1920 0 res 1920x1080
    focus HDMI-A-2
    workspace 1 output HDMI-A-2
    workspace 2 output DP-2
  '';
}
