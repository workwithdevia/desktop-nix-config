# ❄️ Dotfiles — NixOS + Home Manager

> Configuración declarativa, reproducible y segura para estaciones de trabajo NixOS.

## 🖥️ Hosts

| Host | Tipo | Perfil | `specialArgs` |
|---|---|---|---|
| `pc-wwd` | Escritorio (multi-monitor) | `desktop` | `isLaptop = false` |
| `pc-portatil` | Portátil | `laptop` | `isLaptop = true` |

## 📁 Estructura

```
dotfiles/
├── flake.nix                           # Punto de entrada: inputs, mkHost, outputs
├── install.sh                          # Instalación desde ISO (disko + nixos-install)
├── .clinerules                         # Reglas de expertise (Nix, AD, Sysadmin)
├── .gitlab-ci.yml                      # CI/CD pipeline (alejandra, statix, flake check, build)
├── .editorconfig                       # Estilo de código consistente
├── .envrc                              # direnv (auto-devshell)
├── hosts/                              # Configuraciones específicas por máquina
│   ├── pc-wwd/
│   │   ├── configuration.nix           #   Imports: common-nixos + desktop
│   │   ├── home.nix                    #   Imports: common-home + desktop
│   │   ├── disk.nix                    #   Particionado (disko)
│   │   └── hardware-configuration.nix  #   Auto-generado, no editar manualmente
│   └── pc-portatil/
│       ├── configuration.nix           #   Imports: common-nixos + laptop
│       ├── home.nix                    #   Imports: common-home + laptop
│       ├── disk.nix
│       └── hardware-configuration.nix
├── modules/
│   ├── profiles/                       # Perfiles reutilizables por tipo de host
│   │   ├── common-nixos.nix            #   NixOS base (core, desktop, podman, secrets, hardening)
│   │   ├── common-home.nix             #   Home Manager base (shell, editores, navegadores)
│   │   ├── desktop.nix                 #   Extras escritorio (libvirt, waydroid, rclone, multi-monitor)
│   │   └── laptop.nix                  #   Extras portátil (wifi, tlp, bluetooth, TPM2, eDP-1)
│   ├── nixos/                          # Módulos NixOS (system-level)
│   │   ├── core/                       #   locale, user, nix-settings, security, wifi
│   │   ├── core/security-cis.nix       #   Hardening CIS Benchmark (5 flags)
│   │   ├── core/luks-tpm.nix           #   LUKS + TPM2 auto-unlock (portátiles)
│   │   ├── desktop/                    #   Sway compositor
│   │   ├── secrets/                    #   sops-nix (AGE encryption)
│   │   └── virtualisation/            #   podman, libvirt, waydroid, android, docker
│   └── home/                           # Módulos Home Manager (user-level)
│       ├── desktop/                    #   Sway + DankMaterialShell + Winapps
│       ├── packages/                   #   cli, apps, dev, wayland, fonts
│       ├── services/                   #   rclone-google-drive
│       ├── zsh/                        #   Shell + p10k + plugins
│       ├── wezterm/                    #   Terminal emulator
│       ├── zellij/                     #   Terminal multiplexer
│       ├── nvim/                       #   Neovim (lazy.nvim)
│       ├── git.nix
│       ├── fzf.nix
│       ├── brave.nix / firefox.nix
│       ├── vscode.nix / zed.nix
│       ├── danksearch.nix
│       └── session.nix
└── secrets/                            # Secretos cifrados (no se commitean sin cifrar)
    ├── pc-wwd.yaml                     #   sops-nix AGE encrypted
    └── pc-portatil.yaml
```

## 🏗️ Arquitectura

### Perfiles (DRY)

Todo lo compartido entre hosts vive en `modules/profiles/`. Los hosts solo importan 2 archivos:

```nix
# pc-wwd: escritorio con virtualización extendida
imports = [
  ./hardware-configuration.nix
  ../../modules/profiles/common-nixos.nix
  ../../modules/profiles/desktop.nix
];

# pc-portatil: portátil con wifi, tlp, bluetooth
imports = [
  ./hardware-configuration.nix
  ../../modules/profiles/common-nixos.nix
  ../../modules/profiles/laptop.nix
];
```

### Banderas dinámicas (`specialArgs`)

Cada host recibe banderas en tiempo de build que los módulos usan para activar/desactivar servicios condicionalmente:

```nix
# flake.nix
mkHost = hostname: isLaptop: ...;

nixosConfigurations = {
  pc-wwd = mkHost "pc-wwd" false;       # isLaptop = false
  pc-portatil = mkHost "pc-portatil" true; # isLaptop = true
};
```

| Bandera | Efecto |
|---|---|
| `isLaptop = true` | Activa `tlp` (batería), `bluetooth`, `fail2ban`, `wifi`, TPM2 auto-unlock |
| `isLaptop = false` | Activa `auditd`, `libvirt`, `waydroid`, `android`, kernel `lockdown=confidentiality` |
| `hostname` | Configura displays de Sway por host |

### Seguridad (Security-First)

Hardening CIS Benchmark activado por defecto en ambos hosts:

| Flag | pc-wwd | pc-portatil |
|---|---|---|
| `enableAppArmor` | ✅ | ✅ |
| `enableKernelHardening` | ✅ | ✅ |
| `enableFirewallStrict` | ✅ | ✅ |
| `enableAuditd` | ✅ | ❌ (ahorro batería) |
| `enableFail2ban` | ❌ | ✅ (redes públicas) |

Secretos gestionados con **sops-nix** (AGE encryption). Nunca se commitean credenciales en texto plano.

### CI/CD

Pipeline en GitLab CI que ejecuta automáticamente en cada push/MR:

```yaml
stages: [format-lint, check, build]
# alejandra --check  →  statix check  →  flake check  →  build ambos hosts
```

## 🚀 Instalación

1. Bootea desde el ISO de NixOS.
2. Ejecuta el script de instalación:

```bash
bash <(curl -sSL https://gitlab.com/workwithdevia-group/desktop/docfiles/-/raw/main/install.sh)
```

3. Ingresa el nombre del host (`pc-wwd` o `pc-portatil`).

El script:
- Clona el repositorio
- Particiona el disco con **disko**
- Instala NixOS con `nixos-install --flake`

## 🛠️ Desarrollo

### Requisitos

- [Nix](https://nixos.org) con flakes habilitados.
- [direnv](https://direnv.net/) + [nix-direnv](https://github.com/nix-community/nix-direnv) (recomendado).

### Entorno de desarrollo

```bash
cd dotfiles     # direnv activa el devshell automáticamente
# o manualmente:
nix develop
```

| Herramienta | Uso |
|---|---|
| `alejandra` | Formateador de Nix |
| `deadnix` | Buscar código muerto en archivos `.nix` |
| `statix` | Linter de Nix |
| `nil` / `nixd` | LSP para editores |
| `nom` (`nix-output-monitor`) | Logs de compilación legibles |
| `nvd` | Diferencias entre generaciones de paquetes |
| `make` (`gnumake`) | Build y deploy vía `Makefile` |
| `nixos-rebuild` | `nixos-rebuild switch --flake` |
| `colmena` | Despliegue remoto multi-host (futuro) |

### Validación local (pre-commit)

```bash
alejandra .
statix check
nix flake check
```

### Build por host

```bash
nix build .#nixosConfigurations.pc-wwd.config.system.build.toplevel --no-link
nix build .#nixosConfigurations.pc-portatil.config.system.build.toplevel --no-link
```

### Despliegue

```bash
# Build + switch local
sudo nixos-rebuild switch --flake .#pc-wwd

# Actualizar dependencias
nix flake update
```

### Makefile (build + deploy con `nom`)

El `Makefile` agrupa los comandos habituales usando las herramientas del devshell:

```bash
make help              # Lista todos los objetivos
make build             # Build de pc-wwd con nom (nix-output-monitor)
make build HOST=pc-portatil
make build-all         # Build de todos los hosts
make deploy            # Build (nom) + nixos-rebuild switch de pc-wwd
make deploy HOST=pc-portatil
make switch            # Solo nixos-rebuild switch (sudo)
make format / lint / check / validate
make update            # nix flake update
make develop           # Entra en nix develop
```

## 📋 Stack principal

| Categoría | Tecnología |
|---|---|
| **OS** | NixOS (unstable) |
| **Gestor de configuración** | Home Manager |
| **Compositor** | Sway (Wayland) + DankMaterialShell |
| **Shell** | Zsh + Powerlevel10k + plugins |
| **Terminal** | Wezterm + Zellij |
| **Editor** | Neovim (lazy.nvim) + VS Code |
| **Navegador** | Brave + Firefox |
| **Virtualización** | Podman, libvirt, Waydroid |
| **Secretos** | sops-nix (AGE encryption) |
| **Backups** | rclone → Google Drive |
| **CI/CD** | GitLab CI |
| **Hardening** | AppArmor, auditd, fail2ban, kernel lockdown, firewall |

## 🗺️ Roadmap

Ver [`ROADMAP.md`](ROADMAP.md) para el plan completo de mejoras, estado actual, y próximas fases de implementación.

## 📚 Referencias

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [disko](https://github.com/nix-community/disko)
- [CIS Benchmark](https://www.cisecurity.org/benchmark/distribution_independent_linux)
- [SSSD AD Integration](https://sssd.io/docs/design_pages/ad_provider.html)