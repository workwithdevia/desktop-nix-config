#!/usr/bin/env bash
# Script para formatear e instalar NixOS automáticamente
# Debe ejecutarse desde el ISO de NixOS
#
# Uso interactivo:
#   ./install.sh
#
# Uso no interactivo (CI/CD):
#   ./install.sh --host pc-wwd
#   HOSTNAME=pc-portatil ./install.sh

set -e

# 1. Configuración de variables
REPO_URL="https://gitlab.com/workwithdevia-group/desktop/docfiles"
REPO_BRANCH="${REPO_BRANCH:-main}"
TARGET_DIR="/mnt/etc/nixos"

# Procesar argumentos
while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      HOSTNAME="$2"
      shift 2
      ;;
    --help|-h)
      echo "Uso: $0 [--host <hostname>]"
      echo ""
      echo "Opciones:"
      echo "  --host <hostname>  Instalar el host especificado (no interactivo)"
      echo "  --help             Mostrar esta ayuda"
      echo ""
      echo "Hosts disponibles:"
      for d in hosts/*/; do
        echo "  - $(basename "$d")"
      done
      exit 0
      ;;
    *)
      echo "Opción desconocida: $1"
      exit 1
      ;;
  esac
done

# 2. Validar HOSTNAME
if [ -z "$HOSTNAME" ]; then
  echo "=================================================="
  echo "  Asistente de Instalación de NixOS — WWD"
  echo "=================================================="
  echo ""
  echo "Hosts disponibles:"
  for d in hosts/*/; do
    echo "  • $(basename "$d")"
  done
  echo ""
  read -r -p "Introduce el nombre del host a instalar: " HOSTNAME
fi

if [ -z "$HOSTNAME" ]; then
  echo "❌ Error: El nombre del host no puede estar vacío."
  exit 1
fi

if [ ! -d "hosts/$HOSTNAME" ]; then
  echo "❌ Error: El host '$HOSTNAME' no existe en el repositorio."
  echo "   Hosts disponibles: $(ls -dm hosts/*/ | sed 's|hosts/||g; s|/||g')"
  exit 1
fi

echo ""
echo "🖥️  Host seleccionado: $HOSTNAME"
echo "📂 Repositorio:        $REPO_URL ($REPO_BRANCH)"
echo "💿 Destino:            $TARGET_DIR"
echo ""

# 3. Clonar repositorio
echo "--- Clonando repositorio de configuración ---"
rm -rf "$TARGET_DIR"
git clone --branch "$REPO_BRANCH" "$REPO_URL" "$TARGET_DIR"

# 4. Particionar con disko
echo "--- Iniciando particionado con disko para [$HOSTNAME] ---"
nix run github:nix-community/disko -- --mode disko "$TARGET_DIR/hosts/$HOSTNAME/disk.nix"

# 5. Instalar NixOS
echo "--- Instalando NixOS para [$HOSTNAME] ---"
nixos-install --flake "$TARGET_DIR#$HOSTNAME"

echo ""
echo "=================================================="
echo "  ✅ ¡Instalación exitosa!"
echo "  🔄 Puedes reiniciar tu equipo ahora."
echo "=================================================="