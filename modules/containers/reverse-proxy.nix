/*
  modules/containers/reverse-proxy.nix

  part of der-home-server
  created 2026-04-19
*/

{
  config,
  pkgs,
  lib,
  globalConfig,
  ports,
  ...
}:
let
  caddyVersion = "latest";

  publicServices = lib.filterAttrs (_: svc: svc.serviceConfig != { }) config.myServices;
  sortedServiceList = lib.sort (a: b: a.serviceConfig.subdomain < b.serviceConfig.subdomain) (
    lib.attrValues publicServices
  );

  serviceHandlers = lib.concatStringsSep "\n" (
    map (
      svc:
      let
        cfg = svc.serviceConfig;
      in
      ''
        @${cfg.name} host ${cfg.subdomain}.home.lan
        handle @${cfg.name} {
          import auth_verify
          reverse_proxy host.containers.internal:${toString cfg.port}
        }
      ''
    ) sortedServiceList
  );
in
{
  myServices.caddy = {
    containerConfig = {
      volumes.caddy-config = "/opt/caddy/config";
      volumes.caddy-data = "/opt/caddy/data";

      files."Caddyfile" = {
        source = pkgs.writeText "Caddyfile" ''
          {
            # enable admin API
            admin 0.0.0.0:2019
          }

          (my_tls) {
            tls /certs/home.lan.crt /certs/home.lan.key
          }

          https://${globalConfig.staticIP} {
            import my_tls
            redir http://{host}{uri}
          }

          http://${globalConfig.staticIP} {
            handle /cert {
              header Content-Disposition "attachment; filename=root-ca.crt"
              header Content-Type "application/x-x509-ca-cert"
              
              root * /certs
              rewrite * /ca.crt
              file_server
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
            
            handle {
              abort
            }
          }
        '';
      };
    };
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
        device = config.myServices.caddy.containerConfig.volumes.caddy-config;
      };

      volumes.caddy-data.volumeConfig = {
        type = "bind";
        device = config.myServices.caddy.containerConfig.volumes.caddy-data;
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

          environments = {
            TZ = "Europe/Berlin";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # config files
            "${config.myServices.caddy.containerConfig.files."Caddyfile".fullPath}:/etc/caddy/Caddyfile:ro,U"

            # volumes
            "${volumes.caddy-certs.ref}:/certs:ro"

            "${volumes.caddy-config.ref}:/config:U"
            "${volumes.caddy-data.ref}:/data:U"
          ];

          publishPorts = [
            "${toString ports.caddyHttp}:80/tcp"
            "${toString ports.caddyHttps}:443/tcp"
            "${toString ports.caddyHttps}:443/udp"

            # admin port
            "${toString ports.caddyAdmin}:2019/tcp"
          ];
        };
      };
    };
}
