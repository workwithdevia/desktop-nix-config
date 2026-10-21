# Boot Specialisations: Common, Development, Design

## Goal

Provide boot-selectable NixOS configurations for three work modes:

- **Common**: the normal system configuration and default boot entry.
- **Development**: Common plus development tools.
- **Design**: Common plus design and graphics applications.

Use NixOS `specialisation` so Development and Design are built from the same host configuration and appear as selectable system generations at boot. Do not duplicate the Common configuration just to create a third identical generation; make the normal generation identifiable as Common where the bootloader supports it.

## Current Implementation

- `modules/profiles/common-nixos.nix` defines the Common base label and the Development and Design specialisations for both hosts.
- Development adds the existing compiler, LSP, and development application modules through the user's Home Manager imports. Container tools stay in Common because they are already part of the shared package baseline.
- Design adds the existing graphics module through the user's Home Manager imports.
- The default generation is labeled Common; both specialisations use distinct, versioned NixOS labels.
- `nix flake check`, `statix check`, Alejandra, whitespace checks, and builds of both specialisations on both hosts passed.

## Repository Context

- `flake/outputs.nix` constructs both hosts and wires Home Manager through `home-manager.users.${username}`.
- `hosts/pc-wwd/configuration.nix` imports `common-nixos.nix` and `desktop-nixos.nix`.
- `hosts/pc-portatil/configuration.nix` imports `common-nixos.nix` and `laptop-nixos.nix`.
- `modules/profiles/common-home.nix` is the shared Home Manager baseline.
- `modules/home/packages/default.nix` currently imports shared CLI, apps, Wayland, fonts, and container packages.
- Development package modules live under `modules/home/packages/dev/`; `apps/develop.nix` contains development applications.
- Design applications live in `modules/home/packages/apps/graphics.nix`.

Check the current imports before editing: some role-specific package modules exist but are not currently included by the shared package imports. Do not make development or design packages part of Common by importing every package module into the baseline.

## Implementation Requirements

1. Keep the existing host, hardware, security, encryption, and common desktop configuration inherited by every boot choice.
2. Add Development and Design as NixOS specialisations at the narrowest shared profile that matches the intended hosts. Do not make laptop-only or desktop-only services apply to the other host.
3. Keep user applications in Home Manager package modules. Select the appropriate Home Manager package set from each NixOS specialisation so switching boot generations also selects the matching user environment; verify this behavior rather than assuming system-level package changes affect Home Manager.
4. Development should include the existing compiler, LSP, and development application modules. Do not add container tools a second time: they are already part of Common. Design should include the existing graphics module. Common should include neither role-specific set unless it is already part of the shared baseline.
5. Give the boot entries clear, stable names: Common, Development, and Design. Preserve the normal system as the default unless the repository already specifies another default policy.
6. Avoid changing package contents, secrets, unrelated host behavior, or the existing profile architecture beyond what is required to select these variants.

## Validation

- Run `alejandra` on changed Nix files and `statix check`.
- Run `nix flake check`.
- Build the affected host system generations, including both hosts if the specialisations are shared.
- Confirm the evaluated configuration exposes the expected specialisations and that the boot menu labels are distinct.
- Confirm Common does not gain Development or Design packages, and that each role gets its intended Home Manager package set.
- Report any build or validation failure that predates the change separately; do not silently broaden the task to fix unrelated issues.

Follow the repository-wide conventions in `.clinerules` while implementing this brief.
