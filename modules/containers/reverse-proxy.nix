/*
  modules/containers/reverse-proxy.nix

  part of der-home-server
  created 2026-04-12
*/

{
  config,
  globalConfig,
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

    db = {
      port = ports.pgadmin;
      policy = "bypass";
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

    bak = {
      port = ports.borg;
      policy = "bypass";
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

    flow = {
      port = ports.node-red;
      policy = "one_factor";
      group = "admins";
    };

    lidarr = {
      port = ports.lidarr;
      policy = "bypass";
    };

    ll = {
      port = ports.lidarrLists;
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

    transfer = {
      port = ports.transferSH;
      policy = "bypass";
    };

    git = {
      port = ports.giteaHttp;
      policy = "bypass";
    };

    papra = {
      port = ports.papra;
      policy = "bypass";
    };

    finance = {
      port = ports.ebk;
      policy = "bypass";
    };

    dav = {
      port = ports.radicale;
      policy = "bypass";
    };

    pdf = {
      port = ports.stirling;
      policy = "one_factor";
      group = "users";
    };

    archiver = {
      port = ports.open-archiver;
      policy = "one_factor";
      group = "users";
    };

    links = {
      port = ports.linkwarden;
      policy = "bypass";
    };
  };

  autheliaRules = [
    {
      domain = "auth.home.lan";
      policy = "bypass";
    }
    {
      domain = "ldap.home.lan";
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

            # admin port
            "${toString ports.caddyAdmin}:2019/tcp"
          ];
        };
      };
    };
}
