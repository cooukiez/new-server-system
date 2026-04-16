{
  config,
  pkgs,
  globalConfig,
  ...
}:
{
  age.secrets = {
    tailscale-key.file = ../../../secrets/s_tailscale-key.age;
  };

  networking = {
    hostName = globalConfig.hostname;
    hostId = "deaf25e4";
    useDHCP = false;

    nameservers = globalConfig.dnsServers;
    interfaces.enp0s20f0u4.ipv4.addresses = [
      {
        address = globalConfig.staticIP;
        prefixLength = 24;
      }
    ];

    defaultGateway = "192.168.178.1";
    networkmanager.enable = true;

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

  #
  # remote access
  #
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    disableUpstreamLogging = true;

    authKeyFile = config.age.secrets.tailscale-key.path;

    extraUpFlags = [
      "--advertise-exit-node"
      "--advertise-routes=192.168.178.0/24"
    ];
  };

  services.networkd-dispatcher = {
    enable = true;
    rules."50-tailscale-optimizations" = {
      onState = [ "routable" ];
      script = ''
        ${pkgs.ethtool}/bin/ethtool -K eth0 rx-udp-gro-forwarding on rx-gro-list off
      '';
    };
  };
}
