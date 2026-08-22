#!/usr/bin/env bash
if pgrep -x wf-recorder >/dev/null; then
  pkill -INT wf-recorder
else
  # Capturamos el monitor que tiene el foco
  output=$(swaymsg -t get_outputs | jq -r ".[] | select(.focused) | .name")

  # Lanzamos la grabación especificando la variable $output
  nohup wf-recorder -o "$output" -f ~/$(date +%Y%m%d_%H%M%S).mp4 >/dev/null 2>&1 &
fi

#testing second screen...
