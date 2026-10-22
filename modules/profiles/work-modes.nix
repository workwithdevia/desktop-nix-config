{
  config,
  lib,
  username,
  ...
}: {
  system.nixos.label = "NixOS-${config.system.nixos.version}-Common";

  specialisation = {
    Development.configuration = {
      system.nixos.label = lib.mkForce "NixOS-${config.system.nixos.version}-Development";
      home-manager.users.${username}.imports = [
        ../home/packages/dev
      ];
    };

    Design.configuration = {
      system.nixos.label = lib.mkForce "NixOS-${config.system.nixos.version}-Design";
      home-manager.users.${username}.imports = [
        ../home/packages/design
      ];
    };
  };
}
