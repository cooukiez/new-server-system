/*
  configuration.nix

  part of der-home-server
  created 2026-04-12
*/

# system configuration file

{
  inputs,
  config,
  pkgs,
  lib,
  hostname,
  staticIP,
  dnsServers,
  ports,
  squUID,
  squGID,
  users,
  ...
}:
{

  # disable systemd services that are affecting the boot time
  systemd.services = {
    NetworkManager-wait-online.enable = false;
    plymouth-quit-wait.enable = false;
  };

  systemd.targets.network-online.wantedBy = [ "multi-user.target" ];

  # hostname
  networking = {
    hostName = hostname;
    hostId = "deaf25e4";
    useDHCP = false;

    nameservers = dnsServers;
    interfaces.enp0s20f0u4.ipv4.addresses = [
      {
        address = staticIP;
        prefixLength = 24;
      }
    ];

    defaultGateway = "192.168.178.1";

    networkmanager.enable = true;

    hosts = {
      # staticIP = [ "home.lan" ];
    };

    firewall = {
      enable = true;

      # for vpn connections
      checkReversePath = "loose";

      trustedInterfaces = [
        "tailscale0"
        "podman0"
      ];

      allowedTCPPorts = [
        22 # allow openssh
        53 # allow dns

        80 # allow http for redirect
        443 # allow https

        1221 # for papra
        2283 # for immich
        8096 # for jellyfin
      ];

      allowedUDPPorts = [
        53 # allow dns
        443 # allow https quic

        config.services.tailscale.port
      ];
    };
  };

  # timezone
  time.timeZone = "Europe/Berlin";
  environment.etc."timezone".text = "Europe/Berlin\n";
  services.timesyncd.enable = true;

  # locales / language
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocales = [ ];
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IE.UTF-8";
    LC_IDENTIFICATION = "en_IE.UTF-8";
    LC_MEASUREMENT = "en_IE.UTF-8";
    LC_MONETARY = "en_IE.UTF-8";
    LC_NAME = "en_IE.UTF-8";
    LC_NUMERIC = "en_IE.UTF-8";
    LC_PAPER = "en_IE.UTF-8";
    LC_TELEPHONE = "en_IE.UTF-8";
    LC_TIME = "en_IE.UTF-8";
  };

  console.keyMap = "us";

  # PATH configuration
  environment.localBinInPath = true;

  # passwordless sudo
  security.sudo.wheelNeedsPassword = false;
  security.pki.certificateFiles = [ ./home.lan.crt ];

  # zram configuration
  zramSwap.enable = true;
  zramSwap.memoryPercent = 50;
  zramSwap.algorithm = "lz4";
}
