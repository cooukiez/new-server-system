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
  home.file."containers/caddy/Caddyfile" = {
    text = ''
      (my_tls) {
        tls /etc/cert/home.lan.crt /etc/cert/home.lan.key
      }
      
      (auth_verify) {
        forward_auth host.containers.internal:9091 {
          uri /api/verify?rd=https://auth.home.lan/
          copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
        }
      }

      home.lan {
        import my_tls
        root * /var/www/home
        file_server
      }

      *.home.lan {
        import my_tls

        @auth host auth.home.lan
        handle @auth {
          reverse_proxy host.containers.internal:9091
        }

        @immich host immich.home.lan
        handle @immich {
          import auth_verify
          reverse_proxy host.containers.internal:2283
        }
        
        @dns host dns.home.lan
        handle @dns {
          import auth_verify
          reverse_proxy host.containers.internal:3000
        }

        handle {
          abort
        }
      }
    '';
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.caddy-certs.volumeConfig = {
        type = "bind";
        device = "/etc/cert";
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
          image = "docker.io/library/caddy:latest";
          name = "caddy";
          addCapabilities = [ "NET_BIND_SERVICE" ];

          volumes = [
            # config files
            "${config.home.homeDirectory}/containers/caddy/Caddyfile:/etc/caddy/Caddyfile:ro"

            # volumes
            "${volumes.caddy-certs.ref}:/etc/cert"
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
