# ❄️ nix-config — NixOS + Home Manager

> Configuración declarativa, reproducible y segura para estaciones de trabajo NixOS.

## 🖥️ Hosts

> 📍 ¿Buscas qué mejorar? Consulta el **[roadmap de mejoras](ROADMAP.md)**.

| Host | Tipo | Perfil NixOS | Perfil Home | `specialArgs` |
|---|---|---|---|---|
| `pc-wwd` | Escritorio (multi-monitor) | `desktop-nixos` | `desktop-home` | `isLaptop = false` |
| `pc-portatil` | Portátil | `laptop-nixos` | `laptop-home` | `isLaptop = true` |

## 📁 Estructura

```
nix-config/
├── flake.nix                           # Punto de entrada: inputs, mkHost, outputs
├── flake/
│   ├── outputs.nix                     # Factory de hosts (mkHost), specialArgs, Home Manager
│   ├── devshell.nix                    # Entorno de desarrollo (alejandra, statix, deadnix...)
│   └── packages.nix                    # Paquetes personalizados del flake
├── Makefile                            # Build y deploy vía make (nix develop)
├── .clinerules                         # Reglas de expertise (Nix, AD, Sysadmin)
├── .gitlab-ci.yml                      # CI/CD pipeline (alejandra, statix, flake check, build)
├── .editorconfig                       # Estilo de código consistente
├── .envrc                              # direnv (auto-devshell)
├── .sops.yaml                          # Configuración de sops-nix (AGE keys)
├── .gitignore
├── commitlint.config.js                # Reglas de commitlint
├── prek.toml                           # Configuración de prek (git hooks)
├── hosts/                              # Configuraciones específicas por máquina
│   ├── pc-wwd/
│   │   ├── configuration.nix           #   Imports: common-nixos + desktop-nixos
│   │   ├── home.nix                    #   Imports: common-home + desktop-home
│   │   ├── disk.nix                    #   Particionado (disko)
│   │   └── hardware-configuration.nix  #   Auto-generado, no editar manualmente
│   └── pc-portatil/
│       ├── configuration.nix           #   Imports: common-nixos + laptop-nixos
│       ├── home.nix                    #   Imports: common-home + laptop-home
│       ├── disk.nix
│       └── hardware-configuration.nix
├── modules/
│   ├── profiles/                       # Perfiles reutilizables por tipo de host
│   │   ├── common-nixos.nix            #   NixOS base (core, desktop, podman, secrets, hardening)
│   │   ├── common-home.nix             #   Home Manager base (shell, editores, navegadores)
│   │   ├── desktop-nixos.nix           #   Extras NixOS escritorio (GitLab Runner)
│   │   ├── desktop-home.nix            #   Extras Home escritorio (rclone, multi-monitor)
│   │   ├── laptop-nixos.nix            #   Extras NixOS portátil (wifi, tlp, bluetooth)
│   │   └── laptop-home.nix             #   Extras Home portátil (display eDP-1)
│   ├── nixos/                          # Módulos NixOS (system-level)
│   │   ├── default.nix
│   │   ├── core/                       #   locale, user, audio, nix-settings, security, wifi, luks-tpm
│   │   │   ├── default.nix
│   │   │   ├── locale.nix
│   │   │   ├── audio.nix               #     PipeWire + WirePlumber
│   │   │   ├── luks-tpm.nix            #     LUKS + TPM2 auto-unlock (portátiles)
│   │   │   ├── nix-settings.nix
│   │   │   ├── security-cis.nix        #     Hardening CIS Benchmark (5 flags)
│   │   │   ├── security.nix
│   │   │   ├── user.nix
│   │   │   └── wifi.nix
│   │   ├── desktop/                    #   Sway compositor (+ niri, inactivo)
│   │   │   ├── default.nix
│   │   │   ├── dcal.nix
│   │   │   ├── niri/                   #   inactivo (no importado)
│   │   │   └── sway/
│   │   ├── secrets/                    #   sops-nix (AGE encryption)
│   │   ├── services/                   #   gitlab-runner
│   │   └── virtualisation/             #   podman, libvirt, waydroid, android, docker
│   │       ├── android.nix
│   │       ├── docker.nix
│   │       ├── libvirt.nix
│   │       ├── podman.nix
│   │       └── waydroid.nix
│   └── home/                           # Módulos Home Manager (user-level)
│       ├── default.nix
│       ├── brave.nix / chrome.nix / firefox.nix
│       ├── danksearch.nix / dcal.nix
│       ├── fzf.nix / git.nix / session.nix
│       ├── vscode.nix / zed.nix
│       ├── desktop/                    #   Sway + DankMaterialShell + Winapps (niri inactivo)
│       │   ├── default.nix
│       │   ├── dank-material-shell/
│       │   ├── niri/                   #   inactivo (no importado)
│       │   ├── sway/
│       │   └── winapps/
│       ├── packages/                   #   cli, apps, dev, wayland, fonts
│       │   ├── default.nix
│       │   ├── fonts.nix
│       │   ├── apps/                   #     develop, graphics, media, office, torrent
│       │   ├── cli/                    #     core, network
│       │   ├── dev/                    #     compilers, containers, lsp
│       │   └── wayland/                #     utils
│       ├── services/                   #   rclone-google-drive
│       ├── zsh/                        #   Shell + p10k + plugins
│       ├── wezterm/                    #   Terminal emulator
│       ├── zellij/                     #   Terminal multiplexer
│       ├── nvim/                       #   Neovim (lazy.nvim)
│       └── ...
├── scripts/
│   ├── install.sh                      # Instalación desde ISO (disko + nixos-install)
│   ├── validate-commit-msg             # Validación de mensajes de commit
│   └── ci/                             # Scripts de CI (check-branch, check-commits)
└── secrets/                            # Secretos cifrados (no se commitean sin cifrar)
    ├── pc-wwd.yaml                     #   sops-nix AGE encrypted
    └── pc-portatil.yaml
```

## 🏗️ Arquitectura

### Perfiles (DRY)

Todo lo compartido entre hosts vive en `modules/profiles/`. Los hosts solo importan 2 archivos (uno para NixOS y otro para Home Manager):

```nix
# hosts/pc-wwd/configuration.nix — escritorio con virtualización extendida
imports = [
  ./hardware-configuration.nix
  ../../modules/profiles/common-nixos.nix
  ../../modules/profiles/desktop-nixos.nix
];

# hosts/pc-wwd/home.nix — Home Manager del escritorio
imports = [
  ../../modules/profiles/common-home.nix
  ../../modules/profiles/desktop-home.nix
];
```

```nix
# hosts/pc-portatil/configuration.nix — portátil con wifi, tlp, bluetooth
imports = [
  ./hardware-configuration.nix
  ../../modules/profiles/common-nixos.nix
  ../../modules/profiles/laptop-nixos.nix
];

# hosts/pc-portatil/home.nix — Home Manager del portátil
imports = [
  ../../modules/profiles/common-home.nix
  ../../modules/profiles/laptop-home.nix
];
```

### Banderas dinámicas (`specialArgs`)

Cada host recibe banderas en tiempo de build que los módulos usan para activar/desactivar servicios condicionalmente:

```nix
# flake/outputs.nix
mkHost = hostname: isLaptop:
  inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs username system hostname isLaptop; };
    ...
  };

nixosConfigurations = {
  pc-wwd = mkHost "pc-wwd" false;       # isLaptop = false
  pc-portatil = mkHost "pc-portatil" true; # isLaptop = true
};
```

| Bandera | Efecto |
|---|---|
| `isLaptop = true` | Activa `tlp` (batería), `bluetooth`, `fail2ban`, `wifi`, TPM2 auto-unlock |
| `isLaptop = false` | Activa `auditd`, kernel `lockdown=confidentiality` |
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
bash <(curl -sSL https://gitlab.com/workwithdevia-group/desktop/nix-config/-/raw/main/install.sh)
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
cd nix-config   # direnv activa el devshell automáticamente
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
| **Compositor** | Sway (Wayland) + DankMaterialShell (+ niri, inactivo) |
| **Shell** | Zsh + Powerlevel10k + plugins |
| **Terminal** | Wezterm + Zellij |
| **Editor** | Neovim (lazy.nvim) + VS Code + Zed |
| **Navegador** | Brave + Chrome + Firefox |
| **Virtualización** | Podman (libvirt, waydroid, android y docker pendientes de activación) |
| **Secretos** | sops-nix (AGE encryption) |
| **Backups** | rclone → Google Drive |
| **CI/CD** | GitLab CI + GitLab Runner |
| **Hardening** | AppArmor, auditd, fail2ban, kernel lockdown, firewall |

##  Referencias

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [disko](https://github.com/nix-community/disko)
- [CIS Benchmark](https://www.cisecurity.org/benchmark/distribution_independent_linux)
- [SSSD AD Integration](https://sssd.io/docs/design_pages/ad_provider.html)