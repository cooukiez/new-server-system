/*
  modules/nixos/services/default.nix

  part of der-home-server
  created 2026-04-02
*/

{
  config,
  pkgs,
  staticIP,
  ...
}:
{
  imports = [
    ./certificate.nix
    ./metrics.nix
    ./structure.nix
  ];

  age.secrets = {
    tailscale-key = {
      file = ../../../secrets/tailscale-key.age;
    };
  };

  services.fwupd.enable = true;
  services.vnstat.enable = true;

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

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "smbnix";
        "netbios name" = "smbnix";
        "security" = "user";

        "guest account" = "nobody";
        "map to guest" = "bad user";
      };

      "root-share" = {
        "path" = "/";
        "browseable" = "no";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "admin";
        "force user" = "admin";
      };
    };
  };

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
