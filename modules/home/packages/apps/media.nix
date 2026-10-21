{pkgs, ...}: {
  home.packages = with pkgs; [
    ffmpeg
    vlc
  ];

  # Crea la carpeta y enlaza el archivo .lua automáticamente en la ruta correcta de Linux
  home.file.".local/share/vlc/lua/extensions/subtitler.lua".source = ./subtitler.lua;
}
