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
  caddyVersion = "latest";
in
{
  home.file."containers/caddy/Caddyfile" = {
    text = ''
      (my_tls) {
        tls /etc/cert/home.lan.crt /etc/cert/home.lan.key
      }

      (auth_verify) {
        forward_auth host.containers.internal:${toString ports.authelia} {
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
          reverse_proxy host.containers.internal:${toString ports.authelia}
        }
        
        @dns host dns.home.lan
        handle @dns {
          import auth_verify
          reverse_proxy host.containers.internal:${toString ports.adguard}
        }

        @vpn host vpn.home.lan
        handle @vpn {
          import auth_verify
          reverse_proxy host.containers.internal:${toString ports.gluetunWebUI}
        }

        @immich host immich.home.lan
        handle @immich {
          import auth_verify
          reverse_proxy host.containers.internal:${toString ports.immich}
        }

        @jellyfin host jellyfin.home.lan
        handle @jellyfin {
          import auth_verify
          reverse_proxy host.containers.internal:${toString ports.jellyfin}
        }

        @lidarr host lidarr.home.lan
        handle @lidarr {
          import auth_verify
          reverse_proxy host.containers.internal:${toString ports.lidarr}
        }

        @slskd host slskd.home.lan
        handle @slskd {
          import auth_verify
          reverse_proxy host.containers.internal:${toString ports.slskdHttp}
        }

        @monitor host monitor.home.lan
        handle @monitor {
          import auth_verify
          reverse_proxy host.containers.internal:${toString ports.grafana}
        }

        @glances host glances.home.lan
        handle @glances {
          import auth_verify
          reverse_proxy host.containers.internal:${toString ports.glances}
        }

        @prometheus host prometheus.home.lan
        handle @prometheus {
          import auth_verify
          reverse_proxy host.containers.internal:${toString ports.prometheus}
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
          image = "docker.io/library/caddy:${caddyVersion}";
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
            "${toString ports.caddyHttp}:80/tcp"
            "${toString ports.caddyHttps}:443/tcp"
            "${toString ports.caddyHttps}:443/udp"
          ];
        };
      };
    };
}