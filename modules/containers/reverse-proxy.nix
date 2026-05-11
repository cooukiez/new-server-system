/*
  modules/containers/reverse-proxy.nix

  part of der-home-server
  created 2026-04-19
*/

{
  config,
  pkgs,
  lib,
  hostConfig,
  images,
  ports,
  publicServices,
  ...
}:
let
  sortedServiceList = lib.sort (a: b: a.serviceConfig.subdomain < b.serviceConfig.subdomain) (
    lib.filter (s: s.serviceConfig.disableProxy == false) (lib.attrValues publicServices)
  );

  serviceHandlers = lib.trim (
    lib.concatStringsSep "\n" (
      map (
        svc:
        let
          cfg = svc.serviceConfig;
        in
        ''
          @${cfg.serviceName} host ${cfg.subdomain}.home.lan
          handle @${cfg.serviceName} {
            import auth_verify
            reverse_proxy host.containers.internal:${toString cfg.port}
          }
        ''
      ) sortedServiceList
    )
  );
in
{
  home.file."containers/caddy/Caddyfile" = {
    text = ''
        {
          # enable admin API
          admin 0.0.0.0:2019

          servers {
            max_header_size 32768
          }
        }

        (my_tls) {
          tls /certs/home.lan.crt /certs/home.lan.key
        }

        https://${hostConfig.staticIP} {
          import my_tls
          redir http://{host}{uri}
        }

        http://${hostConfig.staticIP} {
          handle /cert {
            header Content-Disposition "attachment; filename=root-ca.crt"
            header Content-Type "application/x-x509-ca-cert"
            
            root * /certs
            rewrite * /ca.crt
            file_server
          }

          handle /papra* {
            reverse_proxy http://host.containers.internal:${toString ports.papra}
          }

          handle /immich* {
            reverse_proxy http://host.containers.internal:${toString ports.immich}
          }

          handle /jellyfin* {
            reverse_proxy http://host.containers.internal:${toString ports.jellyfin}
          }

          handle {
            redir https://home.lan
          }
        }

        (auth_verify) {
          forward_auth host.containers.internal:${toString ports.authelia} {
            uri /api/verify?rd=https://auth.home.lan/
            copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
          }
        }

        home.lan {
          import my_tls
          reverse_proxy host.containers.internal:${toString ports.homepage}
        }

        *.home.lan {
          import my_tls

          @auth host auth.home.lan
          handle @auth {
            reverse_proxy host.containers.internal:${toString ports.authelia}
          }

          @ldap host ldap.home.lan
          handle @ldap {
            reverse_proxy host.containers.internal:${toString ports.lldapWeb}
          }

      ${serviceHandlers}

          @dav host dav.home.lan
          handle @dav {
            import auth_verify
            reverse_proxy host.containers.internal:${toString ports.radicale} {
              header_up X-Remote-User {http.auth.user.id}
            }
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
        device = "/etc/certs";
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
          image = "docker-archive:${pkgs.dockerTools.pullImage images.caddy}";
          name = "caddy";
          addCapabilities = [ "NET_BIND_SERVICE" ];

          environments = {
            TZ = "Europe/Berlin";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # config
            "${config.home.homeDirectory}/containers/caddy/Caddyfile:/etc/caddy/Caddyfile:ro,U"

            # volumes
            "${volumes.caddy-certs.ref}:/certs:ro"

            "${volumes.caddy-config.ref}:/config:U"
            "${volumes.caddy-data.ref}:/data:U"
          ];

          publishPorts = [
            "${toString ports.caddyHttp}:80/tcp"
            "${toString ports.caddyHttps}:443/tcp"
            "${toString ports.caddyHttps}:443/udp"

            "${toString ports.caddyAdmin}:2019/tcp"
          ];
        };
      };
    };
}
