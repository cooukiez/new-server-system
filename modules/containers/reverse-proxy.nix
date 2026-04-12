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

  services = {
    #
    # administration
    #
    dns = {
      port = ports.adguard;
      policy = "one_factor";
      group = "admins";
    };

    vpn = {
      port = ports.gluetunWebUI;
      policy = "one_factor";
      group = "admins";
    };

    glances = {
      port = ports.glances;
      policy = "one_factor";
      group = "admins";
    };

    monitor = {
      port = ports.grafana;
      policy = "bypass";
    };

    prometheus = {
      port = ports.prometheus;
      policy = "one_factor";
      group = "admins";
    };

    vnstat = {
      port = ports.vnstat;
      policy = "one_factor";
      group = "admins";
    };

    #
    # services
    #
    immich = {
      port = ports.immich;
      policy = "bypass";
    };

    jellyfin = {
      port = ports.jellyfin;
      policy = "bypass";
    };

    lidarr = {
      port = ports.lidarr;
      policy = "bypass";
    };

    slskd = {
      port = ports.slskdHttp;
      policy = "bypass";
    };

    torrent = {
      port = ports.qBittorrent;
      policy = "bypass";
    };
  };

  autheliaRules = [
    {
      domain = "auth.home.lan";
      policy = "bypass";
    }
    {
      domain = "home.lan";
      policy = "bypass";
    }
  ]
  ++ (map (
    name:
    let
      svc = services.${name};
    in
    {
      domain = "${name}.home.lan";
      policy = svc.policy;
    }
    // (if svc ? group then { subject = [ "group:${svc.group}" ]; } else { })
  ) (builtins.attrNames services));

  serviceHandlers = builtins.concatStringsSep "\n" (
    map (name: ''
      @${name} host ${name}.home.lan
      handle @${name} {
        import auth_verify
        reverse_proxy host.containers.internal:${toString services.${name}.port}
      }
    '') (builtins.attrNames services)
  );
in
{
  _module.args.autheliaRules = autheliaRules;

  home.file."containers/caddy/Caddyfile".text = ''
    (my_tls) {
      tls /certs/home.lan.crt /certs/home.lan.key
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

      ${serviceHandlers}
      
      handle {
        abort
      }
    }
  '';

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
            "${volumes.caddy-certs.ref}:/certs"
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
