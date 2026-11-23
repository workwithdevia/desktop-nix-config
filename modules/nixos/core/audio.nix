# Stack de audio: PipeWire + WirePlumber
#
# - PipeWire gestiona el audio (y el vídeo) de forma unificada.
# - WirePlumber actúa como session/policy manager y se activa automáticamente
#   al habilitar `services.pipewire` (default del backend en nixpkgs).
# - `alsa.enable` integra ALSA con PipeWire.
{
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    wireplumber.enable = true;

    # Salida simultánea: USB + Jack 3.5 mm
    extraConfig.pipewire."10-combined-output" = {
      "context.modules" = [
        {
          name = "libpipewire-module-combine-stream";

          args = {
            "combine.mode" = "sink";
            "node.name" = "combined_usb_jack";
            "node.description" = "USB + Jack 3.5 mm";

            "combine.latency-compensate" = true;

            "combine.props" = {
              "audio.position" = ["FL" "FR"];
            };

            "stream.props" = {
              "stream.dont-remix" = true;
            };

            "stream.rules" = [
              # USB C-Media
              {
                matches = [
                  {
                    "media.class" = "Audio/Sink";
                    "node.name" = "~alsa_output\\.usb-C-Media_Electronics_Inc.*";
                  }
                ];

                actions = {
                  "create-stream" = {
                    "audio.position" = ["FL" "FR"];
                    "combine.audio.position" = ["FL" "FR"];
                  };
                };
              }

              # Jack 3.5 mm integrado
              {
                matches = [
                  {
                    "media.class" = "Audio/Sink";
                    "node.name" = "alsa_output.pci-0000_00_1f.3.analog-stereo";
                  }
                ];

                actions = {
                  "create-stream" = {
                    "audio.position" = ["FL" "FR"];
                    "combine.audio.position" = ["FL" "FR"];
                  };
                };
              }
            ];
          };
        }
      ];
    };
  };
}
