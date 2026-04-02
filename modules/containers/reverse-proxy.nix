/*
  modules/containers/reverse-proxy.nix

  part of der-home-server
  created 2026-04-02
*/

{
  config,
  staticIP,
  ...
}:
{
  home.file."/containers/caddy/Caddyfile" = {
    text = ''
      (my_tls) {
        tls /etc/caddy/certs/home.lan.crt /etc/caddy/certs/home.lan.key
      }

      home.lan {
        import my_tls
        root * /var/www/home
        file_server
      }

      *.home.lan {
        import my_tls
        
        @dns host dns.home.lan
        handle @dns {
            reverse_proxy 127.0.0.1:3000
        }

        handle {
            abort
        }
      }

      ${staticIP}:3000 {
        reverse_proxy host.containers.internal:3000
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
            "80:80/tcp"
            "443:443/tcp"
            "443:443/udp"
            "3000:3000/tcp"
          ];
        };
      };
    };
}
