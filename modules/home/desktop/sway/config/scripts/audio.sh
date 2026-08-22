#!/usr/bin/env bash
if pgrep -x ffmpeg >/dev/null; then
  pkill ffmpeg
else
  # Ajusta 'hw:0' o el dispositivo según tu sistema con 'arecord -l'
  ffmpeg -y -f pulse -i 53 ~/$(date +%Y%m%d_%H%M%S).mp3 &
fi
