# ==============================================================================
# Makefile — Dotfiles NixOS
#
# Objetivos de build y despliegue para los hosts declarados en `flake.nix`.
# Las recetas se ejecutan DENTRO de `nix develop` para usar las herramientas
# instaladas en el devshell (nom, alejandra, statix, deadnix, nvd...).
#
# Uso rapido:
#   make help                     -> lista todos los objetivos
#   make build                    -> build del host por defecto (pc-wwd)
#   make build HOST=pc-portatil   -> build de un host concreto
#   make build-all                -> build de todos los hosts
#   make deploy                   -> build + nixos-rebuild switch
#   make format / lint / check / update
# ==============================================================================

SHELL := $(shell command -v bash)
.DEFAULT_GOAL := help

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------

# Host por defecto (sobrescribible: make build HOST=pc-portatil)
HOST  ?= pc-wwd
HOSTS := pc-wwd pc-portatil

FLAKE := .

# Nix con flakes + nix-command (features experimentales)
NIX := nix --extra-experimental-features "nix-command flakes"

# Ejecuta un comando dentro del entorno declarado en `flake.nix`
DEV := nix develop -c

# Build con salida de `nix build` (se muestra el log plano, sin TUI de nom)
BUILD := $(DEV) nix build --no-link

# Ruta del toplevel de un host en el flake (el `\#` evita que make lo trate como comentario)
TOPLEVEL = .\#nixosConfigurations.$(HOST).config.system.build.toplevel

# ------------------------------------------------------------------------------
# Ayuda
# ------------------------------------------------------------------------------

help: ## Muestra esta ayuda
	@echo "Dotfiles NixOS — objetivos disponibles:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "  Variable HOST = $(HOST)  (cambiala con: make build HOST=pc-portatil)"

# ------------------------------------------------------------------------------
# Entorno de desarrollo
# ------------------------------------------------------------------------------

develop: ## Entra en el shell de desarrollo interactivo (nix develop)
	$(NIX) develop

shell: develop ## Alias de `develop`

# ------------------------------------------------------------------------------
# Build
# ------------------------------------------------------------------------------

build: ## Build del host (HOST) con nix build (sin TUI de nom)
	$(BUILD) $(TOPLEVEL)

build-all: ## Build de todos los hosts
	@for h in $(HOSTS); do \
		echo "==> Building $$h"; \
		$(BUILD) .#nixosConfigurations.$$h.config.system.build.toplevel || exit 1; \
	done

# ------------------------------------------------------------------------------
# Despliegue
# ------------------------------------------------------------------------------

switch: ## nixos-rebuild switch del host (HOST) (requiere sudo)
	sudo nixos-rebuild switch --flake $(FLAKE)#$(HOST)

deploy: ## Build + switch del host (HOST)
	$(BUILD) $(TOPLEVEL)
	sudo nixos-rebuild switch --flake $(FLAKE)#$(HOST)

# ------------------------------------------------------------------------------
# Calidad de codigo y validacion
# ------------------------------------------------------------------------------

format: ## Formatea todo el repo con alejandra
	$(DEV) alejandra .

fmt: format ## Alias de `format`

lint: ## Lint estatico: statix + deadnix
	$(DEV) statix check
	$(DEV) deadnix

check: ## Verifica el flake completo (evaluacion + checks)
	$(NIX) flake check

validate: format lint check ## Formatea, lint y verifica (pre-commit)

# ------------------------------------------------------------------------------
# Actualizacion y limpieza
# ------------------------------------------------------------------------------

update: ## Actualiza los inputs del flake (nix flake update)
	$(NIX) flake update

clean: ## Elimina los resultados de build locales
	rm -f result result-*

gc: ## Garbage collection del store de Nix (requiere sudo)
	sudo nix-collect-garbage -d
