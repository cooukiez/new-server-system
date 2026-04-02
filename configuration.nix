/*
  configuration.nix

  part of der-home-server
  created 2026-04-02
*/

# system configuration file

{
  inputs,
  config,
  pkgs,
  lib,
  hostname,
  dnsServers,
  users,
  ...
}:
{
  imports = [
    # import generated hardware configuration
    ./hardware-configuration.nix

    # import other system configuration modules
    inputs.self.nixosModules.common
    inputs.self.nixosModules.services

    inputs.home-manager.nixosModules.home-manager
    inputs.quadlet-nix.nixosModules.quadlet
    inputs.agenix.nixosModules.default
  ];
  nixpkgs = {
    # add overlays here
    overlays = [
      inputs.self.overlays.additions
      inputs.self.overlays.modifications
      inputs.self.overlays.unstable-packages
      inputs.self.overlays.nur
    ];

    # configure nixpkgs instance
    config = {
      # allow unfree packages
      allowUnfree = true;
      permittedInsecurePackages = [
        "dotnet-sdk-6.0.428"
        "dotnet-runtime-6.0.36"
      ];
    };
  };
  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
      myNixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    in
    {
      settings = {
        # enable flakes and new nix command
        experimental-features = "nix-command flakes";
        # opinionated: disable global registry
        flake-registry = "";
        # workaround for https://github.com/NixOS/nix/issues/9574
        nix-path = myNixPath;
      };

      # opinionated: disable channels
      channel.enable = false;
      # opinionated: make flake registry and nix path match flake inputs
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = myNixPath;

      optimise.automatic = true;
      optimise.dates = [ "03:45" ];
    };

  # boot settings
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    consoleLogLevel = 0;
    initrd.verbose = false;
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
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
  };

  # disable systemd services that are affecting the boot time
  systemd.services = {
    NetworkManager-wait-online.enable = false;
    plymouth-quit-wait.enable = false;
  };

  # hostname
  networking = {
    hostName = hostname;
    hostId = "deaf25e4";
    useDHCP = false;

    nameservers = dnsServers;
    interfaces.enp0s20f0u4.ipv4.addresses = [
      {
        address = "192.168.178.3";
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

      trustedInterfaces = [ "tailscale0" ];

      allowedTCPPorts = [
        22 # allow openssh
        53 # allow dns
        80 # allow http for redirect
        443 # allow https
        2283 # for immich
        3000 # backup dns interface
      ];

      allowedUDPPorts = [
        53 # allow dns

        config.services.tailscale.port
      ];
    };
  };

  # timezone
  time.timeZone = "Europe/Berlin";
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

  # user configuration
  users.users =
    (lib.mapAttrs (_: user: {
      description = user.fullName;
      isNormalUser = true;
      createHome = true;
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
      password = "CHANGE-ME";
      shell = pkgs.zsh;
    }) users)
    // {
      squ = {
        description = "quadlet-user";

        isNormalUser = true;
        createHome = true;
        linger = true;

        group = "squ";
        uid = 10000;

        subUidRanges = [
          {
            startUid = 100000;
            count = 100000;
          }
        ];
        subGidRanges = [
          {
            startGid = 100000;
            count = 100000;
          }
        ];
      };
    };

  users.groups.squ.gid = 10000;

  # virtualisation
  virtualisation.quadlet.enable = true;
  virtualisation.podman.defaultNetwork.settings.dns_enabled = true;

  virtualisation.containers.storage.settings = {
    storage = {
      driver = "overlay";
      options.overlay.mount_program = "/run/current-system/sw/bin/fuse-overlayfs";
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };

    users.squ =
      {
        inputs,
        config,
        pkgs,
        ...
      }:
      {
        imports = [
          inputs.self.containerModules

          inputs.quadlet-nix.homeManagerModules.quadlet
        ];

        home.stateVersion = "25.11";
      };
  };

  # passwordless sudo
  security.sudo.wheelNeedsPassword = false;

  # zram configuration
  zramSwap.enable = true;
  zramSwap.memoryPercent = 50;
  zramSwap.algorithm = "lz4";

  # see https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
