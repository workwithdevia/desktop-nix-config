# 🗺️ Roadmap — Mejoras por realizar en `nix-config`

> Documento vivo. Cada ítem es una mejora concreta y accionable, priorizada por
> impacto · esfuerzo. Se actualiza a medida que se completa el trabajo.

Estado del documento: **revisado el 2026-08-22** contra el estado actual del repo.

---

## 1. Diagnóstico actual (resumen)

El repo ya tiene una base sólida:

- ✅ Flake multi-host (`pc-wwd`, `pc-portatil`) con `specialArgs` (`isLaptop`).
- ✅ Perfiles DRY (`common-*`, `desktop-*`, `laptop-*`) y módulos separados.
- ✅ sops-nix con AGE, hardening CIS por flags, podman, sway + DMS.
- ✅ CI/CD en GitLab con validación (branch, commits, alejandra, statix, deadnix),
  build y deploy por host.
- ✅ Hooks locales con `prek` (deadnix, statix, alejandra, commitlint, `flake check`).

Principales huecos detectados (se desarrollan abajo):

| Área | Déficit |
|---|---|
| Despliegue | `colmena` está en el devshell pero **no está integrado** en `outputs.nix`. Deploy en CI usa `systemd-run` + `nixos-rebuild` ad-hoc. |
| Seguridad | Paquete inseguro permitido (`electron`), runner con `sudo NOPASSWD` + `wheel`, LUKS/TPM2 solo funcional a medias, sin Secure Boot. |
| Secretos | Entradas muertas en `secrets/*.yaml` (`notion`, `dankcal`) ya sin consumidores; keys sin rotación. |
| Backups | Solo `rclone sync` unidireccional, sin restic, sin retención ni verificación de restauración. |
| Observabilidad | No hay métricas (`node_exporter`, Grafana) pese a ser parte del stack declarado. |
| Escritorio | `niri` existe como carpetas pero **no está importado**; sin audio (pipewire) explícito; sin drivers GPU declarados. |
| Higiene | README desactualizado (URL de instalación equivocada, estructura con archivos ya eliminados), ramas git sin limpiar. |
---

## 2. Fase 1 — Cimientos e higiene (quick wins)

Prioridad alta, esfuerzo bajo. Sin riesgo de romper el sistema.

### 1.1 Actualizar README 📚
- **Qué:** corregir la URL de instalación (`install.sh` apunta a
  `github.com/work-with-devia/desktop-nix-config`, el remote real es
  `gitlab.com/workwithdevia-group/desktop/nix-config`); actualizar la estructura
  (ya no existe `modules/home/dcal.nix`); documentar `niri` como *no activo*.
- **Archivos:** `README.md`, `scripts/install.sh`.
- **Criterio de aceptación:** `README.md` describe fielmente el árbol actual;
  `bash <(curl instalación)` funciona desde el remote correcto.

### 1.2 Purgar secretos muertos de sops 🔒
- **Qué:** eliminar `notion.api_key` y `dankcal.google_*` de `secrets/pc-wwd.yaml`
  y `secrets/pc-portatil.yaml` (ya no tienen consumidores tras el refactor).
- **Cómo:** desde una máquina con las claves AGE:
  `sops secrets/pc-wwd.yaml` (editar y borrar las claves). No editar a mano:
  invalidaría el `mac`.
- **Criterio de aceptación:** `sops --decrypt` sigue funcionando y ya no
  existen las claves muertas.

### 1.3 Limpiar grupos del usuario en `user.nix` 🧹
- **Qué:** `users.users.workwithdevia.extraGroups` incluye `docker` y `libvirtd`,
  pero `docker.nix` no está importado y `libvirt.nix` está comentado en
  `desktop-nixos.nix`. Deja solo `networkmanager` y `wheel`, o reactiva los
  módulos (ver 6.1).
- **Criterio de aceptación:** `grep -r docker modules` no arroja referencias a
  un servicio inexistente, o `libvirtd` se activa conscientemente.

### 1.4 Resolver el módulo `niri` huérfano 🖥️
- **Qué:** existen `modules/nixos/desktop/niri` y `modules/home/desktop/niri`
  que **no se importan** en ningún `default.nix`. Decidir: activarlo en un
  perfil o eliminarlo.
- **Criterio de aceptación:** el árbol no contiene carpetas muertas sin
  justificación (`README` o comentario lo documentan).

### 1.5 Definir el stack de audio (pipewire) 🔊
- **Qué:** el repo **no configura audio** explícitamente. Añadir módulo
  `modules/nixos/core/audio.nix` con PipeWire + WirePlumber en `common-nixos`.
- **Criterio de aceptación:** `pactl info` reporta PipeWire en ambos hosts.

### 1.6 Limpiar ramas git 🌿
- **Qué:** hay múltiples ramas `chore/*` y `fix/*` antiguas (`chore/hooks-hotfix-2`,
  etc.). Cerrarlas con MR/merge o borrarlas.
- **Criterio de aceptación:** git branch local solo tiene `main` + ramas en curso.

### 1.7 Unificar networking del portátil 🌐
- **Qué:** `modules/nixos/core/wifi.nix` habilita `NetworkManager`, pero
  `laptop-nixos.nix` usa `networking.wireless` (wpa_supplicant) con el fichero
  de sops. Riesgo de conflicto de dos gestores. Unificar en uno solo (p. ej.
  NetworkManager + `wifi/networks` vía wpa_supplicant **o** NM con WPA2
  enterprise + sops).
- **Criterio de aceptación:** el portátil conecta por wifi y el escritorio por
  cable sin servicios en conflicto (`systemctl list-units | grep -E 'wpa|NetworkManager'`).
---

## 3. Fase 2 — CI/CD y despliegue robusto

### 2.1 Integrar colmena 📦
- **Qué:** añadir `colmena = { meta = {...}; hosts = {...}; }` (o usar `deploy-rs`)
  en `flake/outputs.nix` para despliegue declarativo multi-host, reemplazando el
  `systemd-run` manual del CI.
- **Archivos:** `flake/outputs.nix`, `.gitlab-ci.yml`, `Makefile`.
- **Criterio de aceptación:** `colmena apply --on pc-portatil` despliega sin
  comandos manuales; el devshell ya trae `colmena`.

### 2.2 Binary cache para acelerar CI 🚀
- **Qué:** montar una caché (Attic local vía servicio `atticd` en `pc-wwd`, o
  cachix) y configurar `substituters` en `nix-settings.nix`. Los builds del CI
  dejan de recombinar nixpkgs entero en cada push.
- **Criterio de aceptación:** un push que toca `modules/home` solo recompila lo
  cambiado y descarga el resto de la caché.

### 2.3 Segregar y testear jobs del CI 🧪
- **Qué:** `build-pc-portatil` corre con tag `pc-wwd`; debería correr en el runner
  del portátil o delegar a una caché. Añadir `nix flake check` después de build y
  un test de VM (`nixosTests.<host>` evaluando `toplevel`).
- **Criterio de aceptación:** la pipeline valida, builda y despliega por host con
  los runners correctos.

### 2.4 Alias Makefile + comandos de recuperación 🛟
- **Qué:** añadir targets `make rollback` (activar generación anterior)
  y `make health` (chequeo de servicios críticos).
- **Criterio de aceptación:** `make rollback` deja el sistema en la generación N-1.

---

## 4. Fase 3 — Seguridad y endurecimiento

### 4.1 Eliminar `permittedInsecurePackages` 🔴
- **Qué:** `nix-settings.nix` permite `electron-39.8.10` (inseguro). Ver si aún es
  necesario (dónde se usa ese electron) y, si es posible, comentarlo; si es
  imprescindible, documentar con `TODO(2026-XX, owner)` y plan de upgrade.
- **Criterio de aceptación:** la lista queda vacía o ningún paquete la consume.

### 4.2 Endurecer el runner de GitLab 🛡️
- **Qué:** el runner es `shell` con `sudo NOPASSWD` a `nix` y `nixos-rebuild`, y
  el usuario `gitlab-runner` está en `wheel`. Migrar a executor
  `docker/podman` aislado y ajustar `extraGroups` (quitar `wheel`).
- **Criterio de aceptación:** los jobs corren en contenedores efímeros; el runner
  no tiene `sudo` sobre el sistema salvo el comando mínimo y auditado.

### 4.3 Declarativizar LUKS + TPM2 🔐
- **Qué:** `modules/nixos/core/luks-tpm.nix` solo activa initrd systemd y deja un
  TODO manual (`systemd-cryptenroll`). Añadir un servicio `oneshot`
  (`boot.initrd.luks.devices`) que enrolle la clave en el TPM2 de forma
  idempotente, y decidir si `pc-wwd` pasa a LUKS (hoy su `disk.nix` es ext4
  plano, sin LUKS).
- **Criterio de aceptación:** un host recién instalado se desbloquea con TPM2 sin
  intervención manual; `pc-wwd` tiene decisión documentada (LUKS + TPM o
  declaración explícita de no usarlo).

### 4.4 Secure Boot + firma del bootloader 🪪
- **Qué:** systemd-boot está activo pero sin Secure Boot. Evaluar `sbctl` +
  enroll de la propia clave y/o Lanzaboote (`lanzaboote` en nixpkgs) para
  firmar kernel/initrd.
- **Criterio de aceptación:** `sbctl status` muestra firmware + kernel firmados, o
  queda documentado por qué no procede aún.

### 4.5 Declarar drivers GPU explícitos 🎮
- **Qué:** ambos hosts usan `kvm-intel` pero no hay módulo de gráficos
  (`mesa`/`vulkan`/firmware). Añadir `hardware.graphics.enable` y
  `services.xserver.videoDrivers` (o `hardware.nvidia` si aplica) por host.
- **Criterio de aceptación:** `vulkaninfo` y Wayland corren con aceleración
  declarada, sin paquetes instalados a mano.
---

## 5. Fase 4 — Backups y observabilidad

### 5.1 restic con retención 💾
- **Qué:** sustituir/añadir a rclone sync (unidireccional) un esquema restic:
  repo `restic` en disco + copia a Google Drive vía rclone (ya existe el remote),
  `systemd.timer` diario, retención `hourly/daily/weekly/monthly`, sops para la
  contraseña del repo, y un test mensual de restauración.
- **Archivos:** `modules/home/services/restic.nix` (nuevo), `secrets/*.yaml`.
- **Criterio de aceptación:** `restic snapshots` lista snapshots con retención
  correcta; la restauración se prueba una vez al mes.

### 5.2 Observabilidad 📈
- **Qué:** habilitar `services.prometheus.exporters.node.enable = true` en
  `common-nixos` (o módulo `modules/nixos/services/observability.nix`) y, en
  escritorio, `grafana` + `loki/promtail` para logs estructurados.
- **Criterio de aceptación:** `curl localhost:9100/metrics` responde en ambos hosts;
  un dashboard básico en Grafana (opcional) muestra CPU/RAM/disco.

---

## 6. Fase 5 — Virtualización, escritorio y experiencia dev

### 6.1 Reactivar o eliminar virtualización 🐳
- **Qué:** `desktop-nixos.nix` tiene comentados `waydroid`, `android` y `libvirt`.
  Decidir cuáles se usan, limpiar el `externalInterface = "enp1s0"` hardcodeado en
  `waydroid.nix` (derivarlo de la interfaz activa) y mantener solo lo necesario.
- **Criterio de aceptación:** los módulos activos funcionan y los comentados
  desaparecen (o se documenta "pendiente de activación").

### 6.2 Declarar Android tooling vía `nix develop` 🤖
- **Qué:** si se retoma Android, mover `android-studio`/`android-tools` a un
  devshell por proyecto en vez de `environment.systemPackages`.
- **Criterio de aceptación:** `adb devices` funciona sin paquetes globales.

### 6.3 Integrar Niri como sesión opcional 🖼️
- **Qué:** si se decide mantener `niri`, exponerlo como sesión del greeter
  (`displayManager`) con su home module y status-bar propia.
- **Criterio de aceptación:** `niri` aparece como opción de sesión y sus módulos
  se importan activamente.

### 6.4 Plantilla para añadir un tercer host ➕
- **Qué:** crear `templates/` con `configuration.nix`, `home.nix`, `disk.nix` de
  ejemplo y documentar el flujo (hostname, sops key, profiles). Quitar los
  comentarios "IMPORTANTE: cambia esto" de `hosts/*/disk.nix` usando variables
  reales del host.
- **Criterio de aceptación:** siguiendo el README se puede añadir un host nuevo
  en < 10 minutos.

### 6.5 Experiencia dev (devshell) 🛠️
- **Qué:** añadir a `make validate` la ejecución de `nix flake check` junto a
  alejandra/statix/deadnix, y un script `scripts/dev.sh` que agrupe el flujo.
- **Criterio de aceptación:** `make validate` pasa sin errores en un clone limpio.

---

## 7. Backlog / ideas futuras

- **SSSD / Active Directory**: el `.clinerules` menciona experiencias AD, pero no
  hay integración. Decidir si aplica (entorno corporativo) o eliminarlo de la
  documentación del repo. `TODO(2026-Q4, workwithdevia)`.
- **Waydroid/Android**: definido en 6.1.
- **AppArmor por aplicación** (Firefox, Electron) con perfiles propios.
- **Auditoría de dependencias automática** (`nix audit` o `trivy` sobre
  `toplevel`).
- **Flake `arch`**: `specialArgs` ya reserva `arch`; soportar `aarch64-linux`
  cuando haya un host ARM.
- **Generación de ISO instalable** (`nixos-generators`) para reproducir el
  instalador.
- **Gestión de secretos por host con templating** (`sops` + `templatedKey`).

---

## 8. Métricas de éxito

| Métrica | Objetivo al cierre de Fase 2 |
|---|---|
| Tiempo de `nixos-rebuild` desde CI | < 15 min con caché (vs. hora completa) |
| Secretos sin referencias muertas | 100% (`grep` no arroja `notion`/`dankcal`) |
| Hosts con LUKS+TPM y Secure Boot | 2/2 documentados, 1/2 enrolados (portátil) |
| Backups con restic | restauración probada ≥ 1 vez/mes |
| Despliegue | 100% vía `colmena apply` (sin `systemd-run` manual) |
| Paquetes inseguros | 0 entradas en `permittedInsecurePackages` |

---

💡 **Convención:** cada ítem al tomarlo en curso cambia a `[x]` con fecha y
responsable, siguiendo el formato `TODO(2026-XX, usuario): descripción` que ya
se usa en el repo.