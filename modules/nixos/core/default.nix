{
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./network.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
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

    # required for subnet routing
    kernel.sysctl = {
      "net.ipv4.ip_unprivileged_port_start" = 32;

      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
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

  # passwordless sudo
  security.sudo.wheelNeedsPassword = false;
  security.pki.certificateFiles = [ ./home.lan.crt ];

  # zram configuration
  zramSwap.enable = true;
  zramSwap.memoryPercent = 50;
  zramSwap.algorithm = "lz4";

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      UseDns = true;
      X11Forwarding = false;

      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };
}
