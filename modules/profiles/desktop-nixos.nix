# Perfil: desktop-nixos — NixOS extras para pc-wwd (virtualización extendida + GitLab Runner)
{
  pkgs,
  lib,
  ...
}: {
  nixpkgs.overlays = [
    (final: prev: {
      xdg-desktop-portal-wlr = prev.xdg-desktop-portal-wlr.overrideAttrs (oldAttrs: {
        version = "0.8.2";

        src = oldAttrs.src.override {
          rev = "v0.8.2";
          sha256 = "sha256-HITf/hgiASWvn/z49mzS8IS1vuyXwdk1JiAOOHRSQMo=";
        };
      });
    })
  ];

  imports = [
    /*
    ../nixos/virtualisation/libvirt.nix
    ../nixos/virtualisation/android.nix
    ../nixos/virtualisation/waydroid
    */
    ../nixos/services/gitlab-runner.nix
    ../nixos/services/droidcam.nix
  ];

  services = {
    gitlab-runner-local = {
      enable = true;
      tags = ["pc-wwd" "nixos" "x86_64-linux"];
    };

    droidcam-client.enable = true;

    udev = {
      enable = true;
      extraRules = ''
        # CH340 USB Serial (ESP32)
        SUBSYSTEM=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0666", GROUP="dialout"
        SUBSYSTEM=="usb-serial", DRIVER=="ch341-uart", MODE="0666", GROUP="dialout"
        KERNEL=="ttyUSB*", SUBSYSTEMS=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0666", GROUP="dialout"

        # Picoprobe CMSIS-DAP
        SUBSYSTEM=="usb", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="000c", MODE="0666", GROUP="dialout"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="0003", MODE="0666"
        ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="000c", MODE="0666", GROUP="plugdev"

        # DirtyJTAG (1209:c0ca)
        SUBSYSTEM=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="c0ca", MODE="0666", GROUP="dialout"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="c0ca", TAG+="uaccess"
      '';
    };
  };

  xdg.portal = {
    enable = true;

    wlr.enable = true;

    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];

    config = {
      common = {
        default = ["gtk"];
        "org.freedesktop.impl.portal.ScreenCast" = ["wlr"];
        "org.freedesktop.impl.portal.Screenshot" = ["wlr"];
      };

      sway = {
        default = ["gtk"];
        "org.freedesktop.impl.portal.ScreenCast" = ["wlr"];
        "org.freedesktop.impl.portal.Screenshot" = ["wlr"];
      };
    };
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  environment.systemPackages = with pkgs; [
    fuzzel
    slurp
  ];

  security.rtkit.enable = true;

  programs.chromium = {
    enable = true;
    extraOpts = {
      "PasswordManagerEnabled" = false;
      "AutofillAddressEnabled" = false;
      "AutofillCreditCardEnabled" = false;
      "SearchSuggestEnabled" = false;
      "MetricsReportingEnabled" = false;
      "PrivacySandboxSettingsAllowed" = false;
      "BackgroundModeEnabled" = false;
    };
  };
}
