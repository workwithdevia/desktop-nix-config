#!/usr/bin/env bash

# Make sure user PATH is loaded if dms/jq are in ~/.nix-profile/bin or ~/.local/bin
export PATH="$HOME/.nix-profile/bin:$HOME/.local/bin:$PATH"

APP=$(swaymsg -t get_tree | jq -r '
  ..
  | select(.focused? == true)
  | (.app_id // .window_properties.class // "" | ascii_downcase) as $id
  | (.name // "" | ascii_downcase) as $name
  | if ($id | contains("chromium") or contains("chrome")) then
      "chrome"
    elif ($id == "org.wezfurlong.wezterm") then
      if ($name | contains("nvim")) then "nvim"
      elif ($name | contains("lazygit")) then "lazygit"
      elif ($name | contains("zellij")) then "zellij"
      else "wezterm" end
    else
      $id
    end
')

dms ipc call keybinds toggle "$APP"
