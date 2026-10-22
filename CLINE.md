# Professional Workstation Refactor: Hosts, Work Modes, Applications

## Goal

Refactor the workstation environment into a clear, reproducible system with two independent axes: host hardware/platform profiles and boot-selectable user work modes. The current work modes are:

- **Common**: the normal system configuration and default boot entry.
- **Development**: Common plus development tools.
- **Design**: Common plus design and graphics applications.

Use NixOS `specialisation` so Development and Design extend the same host configuration and appear as selectable system generations at boot. Keep the normal system as the default and label it Common where supported. Do not duplicate the Common configuration to create another identical generation. Keep host hardware, services, and user applications in their existing ownership layers.

## Architecture Audit

### Host and Profile Axes

| Host | NixOS layers | Home Manager layers | Host-owned behavior |
|---|---|---|---|
| `pc-wwd` | `common-nixos` + `work-modes` + `desktop-nixos` | `common-home` + `desktop-home` | Desktop hardware, USB/serial rules, DroidCam, display portals, desktop runner tags, multi-monitor layout, rclone |
| `pc-portatil` | `common-nixos` + `work-modes` + `laptop-nixos` | `common-home` + `laptop-home` | Laptop hardware, TLP, Bluetooth, laptop runner tags, eDP display layout |

`common-nixos.nix` is shared by both hosts. It imports core NixOS configuration, the shared desktop session, Podman, secrets, CIS hardening, LUKS/TPM, and Wi-Fi. Laptop-specific behavior is gated by `isLaptop` or kept in the laptop profile. The shared desktop session currently means Sway/DankMaterialShell is enabled on both hosts; do not change that as a side effect of package-role work.

### Active User Package Sets

| Scope | Active contents | Refactor rule |
|---|---|---|
| Common Home Manager | Shared CLI and network tools, Wayland utilities, fonts, media (`ffmpeg`, VLC), Bitwarden, qBittorrent, `podman-compose`, shell/terminal/editor configuration, Neovim, VS Code, Chromium, DMS | This is the actual baseline on both hosts. Decide explicitly whether media, office, and torrent apps belong on every host; do not move them just because their category names look optional. |
| Development specialisation | `modules/home/packages/dev/`: compiler/toolchain, LSP/build tools, and DBeaver from `apps.nix` | Import the Development bundle only through the selected work-mode specialisation. Keep role apps out of Common unless another active Common feature requires them. |
| Design specialisation | `modules/home/packages/design/default.nix`: Inkscape and GIMP | Import the Design bundle only through the selected work-mode specialisation. |
| Common NixOS runtime | Core services and desktop session plus Podman with Docker compatibility | Keep OS services and runtimes in NixOS; user-facing applications belong in Home Manager. Podman and `podman-compose` stay in Common because DMS Docker Manager is enabled there. |

`modules/home/packages/default.nix` imports CLI, common apps, Wayland, fonts, and `dev/containers.nix`. `apps/default.nix` intentionally imports only media, office, and torrent modules. The Development bundle at `dev/default.nix` imports compilers, LSP, and `dev/apps.nix`, and deliberately excludes containers because Common already supplies them. The Design bundle is isolated in `design/default.nix`.

`modules/profiles/work-modes.nix` owns the Common label plus Development and Design NixOS specialisations and selects the corresponding Home Manager bundle. Each host imports it alongside `common-nixos.nix` and its own desktop/laptop profile. `common-nixos.nix` owns shared services and no longer defines work-mode labels or specialisations.

Common currently needs `gcc`, `lua-language-server`, and `nil` for the Neovim configuration, and `direnv` is enabled by the shared Home Manager configuration. Those are shared-feature dependencies, not a reason to classify all Development tooling as Common. The duplicate declarations in the Development compiler/LSP modules have been removed; do not reintroduce them.

### Scope Findings

- **Decision:** keep Podman and `podman-compose` in Common. The DMS Docker Manager plugin is enabled in the Common Home Manager profile, and Common NixOS provides Podman with Docker compatibility.
- `flake/outputs.nix` adds WinApps and its launcher to every host as NixOS system packages. `modules/home/desktop/winapps/default.nix` exists but is not imported. Decide WinApps host scope independently; do not move it into Development or Design merely because it is an application.
- **Decision:** retain dormant Home Manager modules (`brave.nix`, `firefox.nix`, `zed.nix`, and `desktop/winapps`) and NixOS modules (Docker, Android, libvirt, and Waydroid) as inactive code; README marks their status. Niri remains documented inactive. Do not activate dormant modules by bulk-importing directories.
- Containers remain in Common and are not part of the Development bundle.
- PipeWire's former desktop-specific settings are now consolidated in `modules/nixos/core/audio.nix`, preserving the effective options.
- The README now documents fail2ban and NetworkManager as common to both hosts and clarifies that TPM2 enrollment remains a manual post-install step.

## Current Implementation

- `modules/profiles/work-modes.nix` defines the Common base label and the Development/Design specialisations for both hosts; `common-nixos.nix` contains shared system services only.
- Development applications are organized under `modules/home/packages/dev/`; its bundle imports compilers, LSP/build tools, and DBeaver through `apps.nix`.
- Duplicate Development entries for packages already supplied by Common (`gcc`, `direnv`, `lua-language-server`, and `nil`) were removed while retaining the Common dependencies required by Neovim and direnv.
- Design applications are organized under `modules/home/packages/design/default.nix` and selected through the Design Home Manager imports.
- The default generation is labeled Common; both specialisations use distinct, versioned NixOS labels.
- PipeWire is consolidated in the common audio module with PulseAudio compatibility, 32-bit ALSA, and WirePlumber retained.
- WinApps remains installed as a system package on both hosts from `flake/outputs.nix`; its Home Manager module remains inactive and the README reflects this.
- Alejandra, `statix check`, and editor diagnostics pass. `nix flake check path:.` and a path-based build of both hosts plus all four specialisations pass without the former `pkgs.system` deprecation warning.

## Refactor Principles

Use specialisations for opt-in work modes, not as a replacement for the existing host/profile split. `work-modes.nix` is imported by both hosts, so Development and Design variants intentionally exist on both. Host and hardware behavior continues to layer on top of each variant.

Keep these ownership boundaries:

- Host files own hardware configuration, disk layout, bootloader, hostname, and `system.stateVersion`.
- Host profiles own hardware-adjacent services and behavior: laptop power/Bluetooth/TPM distinctions, desktop USB rules/DroidCam/display integration, and host-specific GitLab Runner tags.
- Common NixOS owns shared security, secrets, networking, audio, and the shared desktop/runtime foundation.
- Common Home Manager owns the baseline user environment. Role-specific user applications stay in Home Manager modules selected by the matching NixOS specialisation.
- Work modes are additive package/configuration sets. They must not toggle unrelated host security, encryption, hardware, runner, or desktop services.
- Do not import every package module into a baseline or role. Use explicit imports and verify the evaluated package set.

### Keep Host-Specific

- Hardware configuration, disk layout, bootloader, hostname, and `system.stateVersion` stay in each host configuration.
- Laptop power management, Bluetooth, TPM/initrd behavior, and the `isLaptop` security distinction stay on the laptop/host axis.
- Desktop USB rules, DroidCam, display/portal settings, and desktop overlays stay in `desktop-nixos.nix` or the corresponding host profile.
- GitLab Runner stays host-profile configured because both hosts use it with different tags. Do not make it a work-mode toggle without a separate requirement.
- `flake/outputs.nix` currently adds WinApps to every host. Audit this as a host-scope cleanup if WinApps is not intended for every machine; do not move it into Development or Design just because it is a package.

### Common Baseline and Mode Packages

- Core locale, audio, networking, security, desktop session, secrets, and existing host imports remain common to all boot choices.
- Media, office, torrent, CLI, fonts, and Wayland utilities are currently in the shared Home Manager package profile. Keep them in Common unless a separate mode requirement explicitly reclassifies them.
- `modules/home/packages/dev/containers.nix` and `modules/nixos/virtualisation/podman.nix` are currently enabled in Common. Moving them to Development is a possible way to make Common leaner, but it changes the default system: the DankMaterialShell Docker Manager plugin is enabled in the common desktop Home Manager profile, while Podman provides the configured Docker-compatible runtime. Verify the plugin's runtime dependency before moving either module; decide whether the plugin should also be Development-only or Podman should remain common.
- Common needs `gcc`, `lua-language-server`, and `nil` for Neovim, and `direnv` is part of the shared Home Manager configuration. Duplicate Development declarations for these packages have been removed; preserve the Common dependencies and avoid reintroducing duplicate package entries.
- PipeWire is configured in the shared core audio module; desktop-specific differences should not be reintroduced without a host requirement.

### Recommended Refactor Sequence

1. **Completed:** Preserve the host/profile architecture and the Common, Development, and Design Home Manager package selection.
2. **Decision for this refactor:** retain the current Common personal-application set (media, Bitwarden, and torrent) to preserve existing behavior. Split optional application bundles only after defining who should receive them and how they are selected.
3. **Decision:** keep Podman and `podman-compose` in Common because the Common DMS Docker Manager depends on a Docker-compatible runtime.
4. **Decision for this refactor:** retain WinApps as a system package on both hosts to avoid changing current host behavior. Its separate Home Manager module remains inactive; revisit ownership/host scope independently, never as part of Development or Design.
5. **Decision:** retain currently dormant modules as documented inactive code. Revisit activation/removal only in a separately scoped change with an explicit host or work-mode requirement; never bulk-import dormant directories.
6. **Completed:** Consolidate PipeWire settings in the shared audio module while preserving the prior effective options.
7. **Completed:** Align README host-security, Wi-Fi, TPM2, and WinApps descriptions with the active imports. Continue reconciling other documentation only when confirmed against configuration.
8. **Completed:** Keep boot labels distinct and verify Home Manager activation in each selected generation; all host/mode toplevels build.
9. **Completed:** Alejandra, statix, `nix flake check path:.`, and explicit builds of both base hosts and all four specialisations pass without the former `pkgs.system` deprecation warning.

## Repository Context

- `flake/outputs.nix` constructs both hosts and wires Home Manager through `home-manager.users.${username}`.
- `hosts/pc-wwd/configuration.nix` imports `common-nixos.nix`, `work-modes.nix`, and `desktop-nixos.nix`.
- `hosts/pc-portatil/configuration.nix` imports `common-nixos.nix`, `work-modes.nix`, and `laptop-nixos.nix`.
- `modules/profiles/common-home.nix` is the shared Home Manager baseline.
- `modules/home/packages/default.nix` imports shared CLI, Common apps, Wayland, fonts, and the Common container package module.
- `modules/home/packages/dev/default.nix` is the Development bundle; `apps.nix` owns DBeaver, while compiler and LSP files own toolchains/build support.
- `modules/home/packages/design/default.nix` is the Design bundle for graphics applications.
- `modules/home/packages/apps/default.nix` is the Common app bundle and currently includes media, office, and torrent, but not Development or Design.
- `modules/home/default.nix` imports Chromium and the shared editor/shell configuration; the Brave, Firefox, and Zed modules are not part of the active import graph.
- `modules/home/desktop/default.nix` imports Sway and DankMaterialShell, not the WinApps Home Manager module.
- `modules/nixos/virtualisation/podman.nix` is active from Common; Docker, Android, libvirt, and Waydroid are not active from current host/profile imports.

Check the current imports before editing: role-specific package modules are selected by `work-modes.nix`, not by the shared package imports. Do not make Development or Design packages part of Common by importing every package module into the baseline.

## Implementation Requirements

1. Keep the existing host, hardware, security, encryption, and common desktop configuration inherited by every boot choice.
2. Define Development and Design as NixOS specialisations in `modules/profiles/work-modes.nix`, imported by both hosts. Do not make laptop-only or desktop-only services apply to the other host.
3. Keep user applications in Home Manager package modules. Select the appropriate Home Manager package set from each NixOS specialisation so switching boot generations also selects the matching user environment; verify this behavior rather than assuming system-level package changes affect Home Manager.
4. Development should include the compiler, LSP, and development-app modules through `modules/home/packages/dev/default.nix`. Design should include graphics through `modules/home/packages/design/default.nix`. Do not add container tools a second time: they are already part of Common. Common should include neither role-specific set unless it is already part of the shared baseline.
5. Give the boot entries clear, stable names: Common, Development, and Design. Preserve the normal system as the default unless the repository already specifies another default policy.
6. Avoid changing package contents, secrets, unrelated host behavior, or the existing profile architecture beyond what is required to select these variants.

## Validation

- Run `alejandra` on changed Nix files and `statix check`.
- Run `nix flake check`.
- Build the affected host system generations, including both hosts if the specialisations are shared.
- Confirm the evaluated configuration exposes the expected specialisations and that the boot menu labels are distinct.
- Confirm Common does not gain Development or Design packages, and that each role gets its intended Home Manager package set.
- Common may retain packages required by active shared features, specifically Neovim's compiler/LSP dependencies and direnv; verify against imports before calling them role leakage.
- Confirm Development includes its toolchain/LSP/apps without duplicate declarations, and Design includes graphics apps without Development-only packages.
- Confirm each host profile still contributes only its own host behavior; Development/Design must not change laptop/desktop services or hardware settings.
- Report any build or validation failure that predates the change separately; do not silently broaden the task to fix unrelated issues.

Follow the repository-wide conventions in `.clinerules` while implementing this brief.
