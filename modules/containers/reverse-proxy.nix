{
  config,
  ...
}:
{
  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.caddyfile.volumeConfig = {
        type = "bind";
        device = "/opt/caddy/Caddyfile";
      };

      volumes.caddy-config.volumeConfig = {
        type = "bind";
        device = "/opt/caddy/config";
      };

      volumes.caddy-data.volumeConfig = {
        type = "bind";
        device = "/opt/caddy/data";
      };

      containers.caddy = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "ghcr.io/library/caddy:latest";
          capAdd = [ "NET_ADMIN" ];

          volumes = [
            "${volumes.caddyfile.ref}:/etc/caddy/Caddyfile"
            "${volumes.caddy-config.ref}:/config"
            "${volumes.caddy-data.ref}:/data"
          ];

          publishPorts = [
            "80:80/tcp"
            "443:443/tcp"
            "443:443/udp"
          ];
        };
      };
    };
}
