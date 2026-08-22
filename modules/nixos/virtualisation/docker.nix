{
  virtualisation.docker.enable = true;
  networking.firewall.trustedInterfaces = ["docker0"];

  security.sudo.extraRules = [
    {
      users = ["workwithdevia"];
      commands = [
        {
          command = "/run/current-system/sw/bin/systemctl start docker";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/systemctl stop docker";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}
