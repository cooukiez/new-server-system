/*
  modules/containers/reverse-proxy.nix

  part of der-home-server
  created 2026-04-08
*/

{
  config,
  staticIP,
  ports,
  ...
}:
let
  gluetunVersion = "latest";
  gluetunKey = "169qzBxFa0ET26rkTWa3akmVopysVilS";
in
{
  age.secrets = {
    gluetun-key = {
      file = ../../secrets/gluetun-key.age;
    };
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
          image = "docker.io/library/caddy:latest";
          name = "gluetun";
          networks = [ "vpn-service-net" ];
          addCapabilities = [
            "NET_ADMIN"
          ];

           environments = {
            VPN_SERVICE_PROVIDER = "protonvpn";
            VPN_TYPE = "wireguard";

            SERVER_COUNTRIES = "Netherlands";

            FREE_ONLY = "on";
            # PORT_FORWARD_ONLY = "on";

            HTTP_CONTROL_SERVER_ADDRESS = ":8888";
            HTTP_CONTROL_SERVER_AUTH_DEFAULT_ROLE = "{\"auth\":\"apikey\",\"apikey\":\"${gluetunKey}\"}";
            VPN_PORT_FORWARDING = "false";
            VPN_LAN_LEAK_ENABLED = "false";

            WIREGUARD_MTU = "1420";
            WIREGUARD_PERSISTENT_KEEPALIVE_INTERVAL = "25s";

            FIREWALL = "off";

            BORINGPOLL_GLUETUNCOM = "on";
          };

          environmentFiles = [
            "/run/secrets/WIREGUARD_KEY"
          ];

          volumes = [
            # secrets
            "${config.age.secrets.gluetun-key.path}:/run/secrets/WIREGUARD_KEY"

            # volumes
            "${volumes.gluetun-data.ref}:/gluetun"
          ];

          devices = [
            "/dev/net/tun"
          ];

          publishPorts = [
            "${toString ports.gluetun}:8888/tcp"
          ];
        };
      };
    };
}