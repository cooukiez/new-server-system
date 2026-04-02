{
  config,
  ...
}:
{
  home.file."/containers/caddy/Caddyfile" = {
    text = ''
      :80 {
          respond "Hello from Home Manager managed Caddy"
      }
    '';

    executable = false;
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
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
          image = "docker.io/library/caddy:latest";
          addCapabilities = [ "NET_ADMIN" ];

          volumes = [
            # config files
            "${config.home.homeDirectory}/containers/caddy/Caddyfile:/etc/caddy/Caddyfile:ro"

            # volumes
            "${volumes.caddy-config.ref}:/config"
            "${volumes.caddy-data.ref}:/data"
          ];

          publishPorts = [
            "127.0.0.1:80:80/tcp"
            "127.0.0.1:443:443/tcp"
            "127.0.0.1:443:443/udp"
          ];
        };
      };
    };
}
