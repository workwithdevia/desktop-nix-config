#!/usr/bin/env bash

# Mapeo de Servicio -> Proceso motor
case "$1" in
libvirt)
  S="virtqemud"
  P="qemu-system-x86_64"
  ;;
docker)
  S="docker"
  P="dockerd"
  ;;
waydroid)
  S="waydroid-container"
  P="waydroid"
  ;;
podman)
  S="podman"
  P="podman"
  ;;
*)
  echo "Uso: $0 {libvirt|docker|waydroid|podman}"
  exit 1
  ;;
esac

# Lógica de Toggle
if pgrep -f "$P" >/dev/null; then
  echo "Deteniendo $1..."
  sudo systemctl stop "$S"
  sudo pkill -9 -f "$P"
else
  echo "Iniciando $1..."
  sudo systemctl start "$S"
fi
