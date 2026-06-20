/*
hosts/dhs/hardware.nix

part of server system
created 2026-05-13 by ludw
*/
{
  pkgs,
  ...
}: {
  hardware.facter = {
    enable = true;
    reportPath = ./facter.json;

    detected.uefi.supported = true;

    detected.graphics.enable = true;

    detected.bluetooth.enable = false;
    detected.camera.ipu6.enable = false;
    detected.fingerprint.enable = false;
  };

  hardware.enableAllFirmware = true;
  services.fwupd.enable = true;

  services.devmon.enable = true;

  # processor and graphics
  services.power-profiles-daemon.enable = true;

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
    ];
  };

  # zram configuration
  zramSwap.enable = true;
  zramSwap.memoryPercent = 50;
  zramSwap.algorithm = "lz4";

  # network
  boot.kernel.sysctl = {
    "net.ipv4.ip_unprivileged_port_start" = 32;

    # required for subnet routing
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # drive
  boot.zfs.forceImportRoot = false;
}
