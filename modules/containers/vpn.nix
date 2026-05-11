/*
  modules/containers/vpn.nix

  part of der-home-server
  created 2026-04-19
*/

{
  config,
  pkgs,
  images,
  ports,
  ...
}:
let
  # todo: gluetun key in agenix
  gluetunKey = "169qzBxFa0ET26rkTWa3akmVopysVilS";
in
{
  myServices.gluetun = {
    serviceConfig = {
      description = "Server VPN Provider";
      serviceType = "Networking";

      subdomain = "vpn";
      port = ports.gluetunWebUI;

      policy = "one_factor";
      group = "admins";

      icon = "gluetun";
    };
  };

  age.secrets =
    let
      mkSecret = name: {
        file = ../../secrets/${name}.age;
      };
    in
    {
      grafana-client-key = mkSecret "s_gluetun-key";
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      networks.vpn-service-net = {
        networkConfig = {
          internal = false;
        };
      };

      volumes.gluetun-data.volumeConfig = {
        type = "bind";
        device = "/opt/gluetun/data";
      };

      containers.gluetun = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.gluetun}";
          name = "gluetun";
          networks = [ "vpn-service-net" ];

          addCapabilities = [
            "NET_ADMIN"
          ];

          environments = {
            TZ = "Europe/Berlin";

            VPN_SERVICE_PROVIDER = "protonvpn";
            VPN_TYPE = "wireguard";

            SERVER_COUNTRIES = "Netherlands";

            FREE_ONLY = "on";

            HTTP_CONTROL_SERVER_ADDRESS = ":8888";
            HTTP_CONTROL_SERVER_AUTH_DEFAULT_ROLE = "{\"auth\":\"apikey\",\"apikey\":\"${gluetunKey}\"}";
            VPN_PORT_FORWARDING = "false";
            VPN_LAN_LEAK_ENABLED = "false";

            WIREGUARD_MTU = "1420";
            WIREGUARD_PERSISTENT_KEEPALIVE_INTERVAL = "25s";
            WIREGUARD_PRIVATE_KEY_SECRETFILE = "/run/secrets/WIREGUARD_KEY";

            FIREWALL = "off";

            BORINGPOLL_GLUETUNCOM = "on";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # secrets
            "${config.age.secrets.gluetun-key.path}:/run/secrets/WIREGUARD_KEY:ro"

            # volumes
            "${volumes.gluetun-data.ref}:/gluetun:U"
          ];

          devices = [
            "/dev/net/tun"
          ];

          publishPorts = [
            "${toString ports.gluetun}:8888/tcp"

            # qbittorrent
            "${toString ports.qBittorrent}:8080/tcp"
            "${toString ports.qBittorrentTorrenting}:6881/tcp"
          ];
        };
      };

      containers.gluetun-webui = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.gluetun-webui}";
          name = "gluetun-webui";
          networks = [ "vpn-service-net" ];

          addCapabilities = [ "NET_RAW" ];

          environments = {
            TZ = "Europe/Berlin";

            GLUETUN_CONTROL_URL = "http://gluetun:8888";
            GLUETUN_API_KEY = gluetunKey;

            TRUST_PROXY = "true";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"
          ];

          publishPorts = [
            "${toString ports.gluetunWebUI}:3000/tcp"
          ];
        };
      };
    };
}
