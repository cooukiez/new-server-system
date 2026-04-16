{
  imports = [
    ./hardware-configuration.nix
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
}
