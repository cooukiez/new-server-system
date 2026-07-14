/*
hosts/dhs/hardware.nix

part of server system
created 2026-05-13 by ludw
*/
{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # kernel modules
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];

  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  # root partition
  boot.zfs.forceImportRoot = false;

  fileSystems."/" = {
    device = lib.mkForce "zroot/local/root";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = lib.mkForce "/dev/disk/by-uuid/1BC0-2314";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # facter modules
  hardware.facter = {
    enable = true;
    reportPath = ./facter.json;

    detected.uefi.supported = true;

    detected.graphics.enable = true;

    detected.bluetooth.enable = false;
    detected.camera.ipu6.enable = false;
    detected.fingerprint.enable = false;
  };

  # core hardware
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

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

  swapDevices = [];

  # network
  boot.kernel.sysctl = {
    "net.ipv4.ip_unprivileged_port_start" = 32;

    # required for subnet routing
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # drive
  fileSystems."/home" = {
    device = lib.mkForce "zroot/local/home";
    fsType = "zfs";
  };

  fileSystems."/media" = {
    device = lib.mkForce "zroot/local/media";
    fsType = "zfs";
  };

  fileSystems."/nix" = {
    device = lib.mkForce "zroot/local/nix";
    fsType = "zfs";
  };

  fileSystems."/opt" = {
    device = lib.mkForce "zroot/local/opt";
    fsType = "zfs";
  };

  fileSystems."/var" = {
    device = lib.mkForce "zroot/local/var";
    fsType = "zfs";
  };
}
