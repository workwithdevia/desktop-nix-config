{pkgs, ...}: {
  boot.kernelModules = [
    "ip_tables"
    "iptable_filter"
    "iptable_nat"
    "iptable_mangle"
  ];

  boot.kernelPackages = pkgs.linuxPackages;

  networking.firewall.trustedInterfaces = ["waydroid0"];
  networking.nat = {
    enable = true;
    internalInterfaces = ["waydroid0"];
    externalInterface = "enp1s0";
  };

  virtualisation.waydroid.enable = true;

  security.sudo.extraRules = [
    {
      users = ["workwithdevia"];
      commands = [
        {
          command = "/run/current-system/sw/bin/systemctl start waydroid-container";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/systemctl stop waydroid-container";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  # Script de inicialización automatizada para Waydroid + libhoudini
  systemd.services.init-waydroid = {
    description = "Inicializar Waydroid e instalar libhoudini via waydroid_script";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    requires = ["waydroid-container.service"];
    after = ["network-online.target" "waydroid-container.service"];

    path = with pkgs; [
      waydroid
      git
      (python3.withPackages (ps: with ps; [requests inquirerpy tqdm]))
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      if [ ! -d "/var/lib/waydroid/cells" ]; then
        echo "Waydroid no esta inicializado. Descargando imagen Minimal/Vanilla..."
        waydroid init -f -c https://ota.waydro.id/system -v https://ota.waydro.id/vendor
      fi

      if [ ! -d "/var/lib/waydroid/waydroid_script" ]; then
        echo "Descargando e instalando libhoudini..."
        cd /var/lib/waydroid
        git clone https://github.com/casualsnek/waydroid_script.git
        cd waydroid_script
        python main.py install libhoudini
      fi
      waydroid prop set qemu.hw.mainkeys 1
    '';
  };
}
