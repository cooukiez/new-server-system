{
  config,
  pkgs,
  lib,
  hostConfig,
  ...
}:
{
  # boot configuration
  boot = {
    kernelPackages = pkgs.linuxPackages_6_18;
    consoleLogLevel = 0;

    initrd.verbose = false;
    initrd.systemd.network.wait-online.enable = false;

    kernelParams = [
      "quiet"
      "rd.udev.log_level=3"
      "boot.shell_on_fail"
    ];

    loader.efi.canTouchEfiVariables = true;
    loader.systemd-boot.enable = true;
    loader.timeout = 0;
  };

  # disable systemd services that are affecting the boot time
  systemd.services = {
    NetworkManager-wait-online.enable = false;
    plymouth-quit-wait.enable = false;
  };

  systemd.targets.network-online.wantedBy = [ "multi-user.target" ];

  # timezone
  time.timeZone = "Europe/Berlin";
  environment.etc."timezone".text = "Europe/Berlin\n";
  services.timesyncd.enable = true;

  networking = {
    hostName = hostConfig.hostname;
    hostId = "deaf25e4";
    useDHCP = false;

    nameservers = hostConfig.dnsServers;
    interfaces.enp0s20f0u4.ipv4.addresses = [
      {
        address = hostConfig.staticIP;
        prefixLength = 24;
      }
    ];

    defaultGateway = "192.168.178.1";
    networkmanager.enable = true;

    firewall = {
      enable = true;
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

  networkConfig.tailscaleServer = true;
  networkConfig.tailscaleOperator = "admin";
  age.secrets.tailscale-key.file = ../../secrets/tailscale-key.age;
  services.tailscale.authKeyFile = config.age.secrets.tailscale-key.path;

  networkConfig.glances = true;
  networkConfig.glancesPort = hostConfig.ports.glances;

  networkConfig.samba.shares = {
    root-share = {
      "path" = "/";
      "browseable" = "no";
      "read only" = "no";
      "guest ok" = "no";
      "valid users" = "admin";
      "force user" = "root";
    };
  };

  # locale configuration
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

  # virtualisation
  virtualisation = {
    quadlet.enable = true;
    podman.defaultNetwork.settings.dns_enabled = true;
    containers.storage.settings.storage = {
      driver = "overlay";
      options.overlay.mount_program = "${lib.getExe pkgs.fuse-overlayfs}";
    };
  };

  # security configuration
  security.sudo.wheelNeedsPassword = false;
  security.pki.certificateFiles = [
    ../../certs/ca.crt
  ];

  services.haveged.enable = true;

  # disable documentation temporary
  documentation.nixos.enable = false;
}
