# Stack de audio: PipeWire + WirePlumber
#
# - PipeWire gestiona el audio (y el vídeo) de forma unificada.
# - WirePlumber actúa como session/policy manager y se activa automáticamente
#   al habilitar `services.pipewire` (default del backend en nixpkgs).
# - `alsa.enable` integra ALSA con PipeWire.
{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
  };
}
