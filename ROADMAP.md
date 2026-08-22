# 🗺️ ROADMAP — Dotfiles NixOS

> Plan de mejoras para el sistema de configuración declarativa de NixOS + Home Manager.

---

## 1. Creación de Perfiles (`modules/profiles/`)

### Problema actual

Las configuraciones de los hosts `pc-wwd` (escritorio) y `pc-portatil` (portátil) tienen imports asimétricos e inconsistentes:

| Aspecto | pc-wwd (escritorio) | pc-portatil (portátil) |
|---|---|---|
| **NixOS imports** | `core`, `desktop`, `podman`, `libvirt`, `waydroid`, `android` | `core`, `wifi`, `desktop`, `podman` |
| **Home imports** | `modules/home` (completo), `packages` (completo), `desktop` (completo) | `sway` suelto, `dms` suelto, paquetes granulares (`cli`, `apps/media`, `apps/torrent`, `apps/office`, `fonts`) |
| **rclone** | ✅ Configurado (sync cada 15min) | ❌ No configurado |
| **Sway displays** | Multi-monitor (HDMI-A-2 + DP-2) | No definido |

Esto genera:
- **Duplicación lógica**: cada host redefine qué módulos necesita manualmente.
- **Riesgo de divergencia**: agregar un módulo común requiere recordar ambos hosts.
- **Dificultad de mantenimiento**: no hay un solo lugar donde ver qué es "común" y qué es "específico".

### Solución propuesta

Crear una jerarquía de perfiles en `modules/profiles/`:

```
modules/profiles/
├── common-nixos.nix     # Imports compartidos de NixOS (core, desktop, podman)
├── common-home.nix       # Imports compartidos de Home Manager (shell, editores, navegadores, paquetes base)
├── desktop.nix           # Extras para pc-wwd (libvirt, waydroid, android, rclone, multi-monitor)
└── laptop.nix            # Extras para pc-portatil (wifi, tlp, bluetooth, monitor único)
```

Cada `hosts/<host>/configuration.nix` y `hosts/<host>/home.nix` se reducen a:
```nix
# configuration.nix
{...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/common-nixos.nix
    ../../modules/profiles/desktop.nix  # o laptop.nix
  ];
  # Solo overrides puntuales del host aquí
}

# home.nix
{...}: {
  imports = [
    ../../modules/profiles/common-home.nix
    ../../modules/profiles/desktop.nix  # o laptop.nix (para extras home)
  ];
  # Solo overrides puntuales del host aquí
}
```

### Beneficios

- ✅ Un solo lugar para ver qué está compartido vs. qué es específico por tipo de máquina.
- ✅ Agregar un nuevo módulo común requiere editar solo 1 archivo (`common-nixos.nix` o `common-home.nix`).
- ✅ Agregar un tercer host (ej. un servidor) es trivial: crear un nuevo perfil y heredar lo común.

---

## 2. Banderas Dinámicas mediante `specialArgs`

### Problema actual

`specialArgs` en `flake.nix` solo pasa `inputs`, `username` y `system`:

```nix
specialArgs = { inherit inputs username system; };
```

No hay forma de que los módulos comunes sepan si están corriendo en un escritorio o un portátil. Esto obliga a duplicar la lógica condicional en los imports de cada host.

### Solución propuesta

Extender `specialArgs` con banderas dinámicas por host:

```nix
mkHost = hostname: isLaptop:
  nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit inputs username system hostname isLaptop;
    };
    ...
  };

nixosConfigurations = {
  pc-wwd = mkHost "pc-wwd" false;       # Escritorio
  pc-portatil = mkHost "pc-portatil" true; # Portátil
};
```

### Usos concretos

| Banderas | Módulo afectado | Comportamiento |
|---|---|---|
| `isLaptop = true` | `modules/nixos/core/` | Habilitar `services.tlp`, `hardware.bluetooth`, `networking.wireless` |
| `isLaptop = false` | `modules/nixos/virtualisation/` | Habilitar `libvirt`, `waydroid`, `android` |
| `hostname` | `modules/home/desktop/sway/` | Seleccionar config de displays (`host-displays`) automáticamente |
| `isLaptop` | `modules/home/services/` | Habilitar/deshabilitar `rclone` según tipo de máquina |
| `isLaptop` | `modules/home/packages/` | Excluir paquetes pesados en portátil (ej. Android Studio, GPU tools) |

Ejemplo de uso en un módulo:
```nix
{ config, lib, isLaptop, ... }: {
  services.tlp.enable = lib.mkDefault isLaptop;
  hardware.bluetooth.enable = lib.mkDefault isLaptop;
}
```

### Beneficios

- ✅ Lógica condicional centralizada en los módulos, no duplicada en los hosts.
- ✅ Agregar un nuevo host con características mixtas (ej. "mini-PC con WiFi pero sin batería") solo requiere ajustar las banderas, no reescribir imports.
- ✅ Los módulos se vuelven reutilizables y autocontenidos.

---

## 3. Mejoras Adicionales

### 3.1 Virtualización modular condicional

Crear `modules/nixos/virtualisation/default.nix` que agrupe todos los backends y habilite cada uno según las banderas:

```nix
{ isLaptop, ... }: {
  imports = [
    ./podman.nix       # Siempre habilitado (ambos hosts)
    ./libvirt.nix      # Solo si !isLaptop
    ./waydroid.nix     # Solo si !isLaptop
    ./android.nix      # Solo si !isLaptop
  ];
}
```

Actualmente cada host importa los módulos de virtualización manualmente en su `configuration.nix`.

### 3.2 Configuración de displays dinámica por host

Mover la lógica de displays de sway fuera del `home.nix` de cada host hacia un módulo que use `hostname` desde `specialArgs`:

```nix
# modules/home/desktop/sway/displays.nix
{ hostname, ... }: {
  xdg.configFile."sway/config.d/host-displays".text =
    if hostname == "pc-wwd" then ''
      output HDMI-A-2 pos 0 0 res 1920x1080
      output DP-2 pos 1920 0 res 1920x1080
      workspace 1 output HDMI-A-2
      workspace 2 output DP-2
    '' else ''
      output eDP-1 pos 0 0 res 1920x1080
      workspace 1 output eDP-1
    '';
}
```

Actualmente está hardcodeado en `hosts/pc-wwd/home.nix` y ausente en `pc-portatil`.

### 3.3 Unificar rclone como módulo condicional

Actualmente `rclone-google-drive` está configurado solo en `hosts/pc-wwd/home.nix`. Moverlo al perfil `desktop.nix` y hacerlo condicional:

```nix
# En modules/profiles/desktop.nix
{ ... }: {
  services.rclone-google-drive = {
    enable = true;
    mode = "sync";
    remoteName = "gdrive";
    remoteRoot = "Backups";
    interval = "15m";
    directories = {
      Documents = {};
      Music = {};
      Images = {};
    };
  };
}
```

### 3.4 Actualizar `install.sh`

El script actual no necesita cambios mayores, pero se sugiere:

- Validar que `HOSTNAME` exista como directorio en `hosts/` antes de clonar.
- Mostrar los hosts disponibles (listar `hosts/*/`).
- Soportar flags no interactivas (`--host pc-wwd`) para automatización CI/CD.

### 3.5 Documentación interna

- Agregar comentarios `# Perfil: común` / `# Perfil: desktop` en cada módulo para trazabilidad.
- Documentar las banderas de `specialArgs` en un comentario al inicio de `flake.nix`.
- Mantener este `ROADMAP.md` actualizado como fuente de verdad del plan de arquitectura.

---

## 4. Resumen de Archivos a Crear/Modificar

| Archivo | Acción | Prioridad |
|---|---|---|
| `modules/profiles/common-nixos.nix` | **Crear** | 🔴 Alta |
| `modules/profiles/common-home.nix` | **Crear** | 🔴 Alta |
| `modules/profiles/desktop.nix` | **Crear** | 🔴 Alta |
| `modules/profiles/laptop.nix` | **Crear** | 🔴 Alta |
| `flake.nix` | **Modificar** (`mkHost` con `isLaptop`, extender `specialArgs`) | 🔴 Alta |
| `hosts/pc-wwd/configuration.nix` | **Modificar** (usar perfiles) | 🔴 Alta |
| `hosts/pc-portatil/configuration.nix` | **Modificar** (usar perfiles) | 🔴 Alta |
| `hosts/pc-wwd/home.nix` | **Modificar** (simplificar, delegar a perfiles) | 🔴 Alta |
| `hosts/pc-portatil/home.nix` | **Modificar** (simplificar, delegar a perfiles) | 🔴 Alta |
| `modules/nixos/virtualisation/default.nix` | **Crear** (agrupar backends condicionales) | 🟡 Media |
| `modules/home/desktop/sway/displays.nix` | **Crear** (displays dinámicos por hostname) | 🟡 Media |
| `install.sh` | **Modificar** (validaciones y mejoras UX) | 🟢 Baja |
| `README.md` | **Modificar** (documentar nueva arquitectura) | 🟢 Baja |

---

## 5. Orden de Implementación Recomendado

1. **Crear los 4 archivos de perfiles** (`modules/profiles/*.nix`) — extraer imports desde los hosts actuales.
2. **Modificar `flake.nix`** — extender `mkHost` con `isLaptop` y `hostname`.
3. **Simplificar `hosts/*/configuration.nix` y `hosts/*/home.nix`** — reemplazar imports manuales por perfiles.
4. **Probar build** — `nix flake check` y `nix build .#nixosConfigurations.pc-wwd.config.system.build.toplevel` (y pc-portatil).
5. **Crear `modules/nixos/virtualisation/default.nix`** — consolidar virtualización condicional.
6. **Crear `modules/home/desktop/sway/displays.nix`** — displays dinámicos.
7. **Actualizar `install.sh`** — mejoras de UX.
8. **Actualizar `README.md`** — reflejar nueva arquitectura.

---

> 💡 **Principio rector:** *"Lo común se hereda, lo específico se declara una sola vez."*