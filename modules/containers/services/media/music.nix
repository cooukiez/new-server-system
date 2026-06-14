/*
modules/containers/services/media/music.nix

part of server system
created 2026-05-13 by ludw
*/
{
  config,
  pkgs,
  lib,
  images,
  ports,
  mkConf,
  downloadPath,
  ...
}: let
  createLidarrConf = import ./settings/soularr.nix {inherit config pkgs mkConf;};
  createSlskdConf = import ./settings/soularr.nix {inherit config pkgs mkConf;};
  createSoularrConf = import ./settings/soularr.nix {inherit config pkgs lib mkConf;};
in {
  myServices = {
    lidarr = {
      serviceConfig = {
        name = "Lidarr";
        description = "Music Tracker / Downloader";
        serviceType = "Restricted";

        subdomain = "lidarr";
        port = ports.lidarr;

        policy = "bypass";

        icon = "lidarr";
      };
    };

    deemix = {
      serviceConfig = {
        name = "Deemix";
        description = "Deezer Downloader";
        serviceType = "Restricted";

        subdomain = "deemix";
        port = ports.deemix;

        policy = "two_factor";
        group = "admins";

        icon = "deemix";
      };
    };

    slskd = {
      serviceConfig = {
        name = "Slskd";
        description = "Soulseek Network Integration";
        serviceType = "Restricted";

        subdomain = "slskd";
        port = ports.slskdHttp;

        policy = "bypass";

        icon = "slskd";
      };
    };
  };

  age.secrets = let
    mkSecret = name: {
      file = ../../../../secrets/${name}.age;
    };
  in {
    lidarr-api-key = mkSecret "containers/lidarr/s_api-key";
    lidarr-db-pass = mkSecret "containers/lidarr/s_db-pass";

    slskd-gluetun-api-key = mkSecret "containers/gluetun/s_api-key";

    slskd-lidarr-api-key = mkSecret "containers/slskd/s_lidarr-api-key";
    slskd-user = mkSecret "containers/slskd/s_user";
    slskd-pass = mkSecret "containers/slskd/s_pass";
    slskd-webui-pass = mkSecret "containers/slskd/s_webui-pass";

    soularr-lidarr-api-key = mkSecret "containers/soularr/s_lidarr-key";
    soularr-slskd-api-key = mkSecret "containers/soularr/s_slskd-key";
  };

  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) volumes networks;
  in {
    volumes.lidarr-db.volumeConfig = {
      type = "bind";
      device = "/opt/lidarr/db";
    };

    volumes.lidarr-data.volumeConfig = {
      type = "bind";
      device = "/opt/lidarr/data";
    };

    volumes.lidarr-cache.volumeConfig = {
      type = "bind";
      device = "/opt/lidarr/cache";
    };

    volumes.deezer-download.volumeConfig = {
      type = "bind";
      device = "${downloadPath}/deezer";
    };

    volumes.deemix-config.volumeConfig = {
      type = "bind";
      device = "/opt/deemix/config";
    };

    volumes.deemix-download.volumeConfig = {
      type = "bind";
      device = "${downloadPath}/deezer/deemix";
    };

    volumes.slskd-data.volumeConfig = {
      type = "bind";
      device = "/opt/slskd/data";
    };

    volumes.slskd-download.volumeConfig = {
      type = "bind";
      device = "${downloadPath}/slskd";
    };

    volumes.soularr-data.volumeConfig = {
      type = "bind";
      device = "/opt/soularr/data";
    };

    containers.lidarr-postgres = {
      autoStart = true;
      serviceConfig = {
        Restart = "always";
        RestartSec = "10";
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.postgres}";
        name = "lidarr-postgres";
        networks = [networks.media-net.ref networks.postgres-net.ref];

        environments = {
          POSTGRES_USER = "admin";
          POSTGRES_PASSWORD_FILE = "/run/secrets/LIDARR_DB_PASS";

          POSTGRES_DB = "lidarr-main";
        };

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          "${volumes.lidarr-db.ref}:/var/lib/postgresql:U"
          "${config.age.secrets.lidarr-db-pass.path}:/run/secrets/LIDARR_DB_PASS:ro"
        ];
      };
    };

    /*
    containers.lidarr = {
      autoStart = true;

      unitConfig = {
        Requires = ["lidarr-postgres.service"];
        After = ["lidarr-postgres.service"];
      };

      serviceConfig = {
        Restart = "always";
        RestartSec = "10";

        ExecStartPre = [
          "+${pkgs.writeShellScript "pre-lidarr" ''
            ${createLidarrConf}

            ${pkgs.coreutils}/bin/mkdir -p "${downloadPath}/deezer/plugin"
            ${pkgs.coreutils}/bin/mkdir -p "${downloadPath}/deezer/deemix"

            ${pkgs.coreutils}/bin/mkdir -p "/opt/lidarr/cache/spotify"

            ${pkgs.coreutils}/bin/cp ${config.home.homeDirectory}/containers/lidarr/config.xml /opt/lidarr/data/config.xml
            ${pkgs.coreutils}/bin/chmod 644 /opt/lidarr/data/config.xml
          ''}"
        ];
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.lidarr}";
        name = "lidarr";
        userns = "keep-id:uid=10000,gid=10000";
        networks = [networks.media-net.ref];

        environments = {
          TZ = "Europe/Berlin";

          PUID = "10000";
          GUID = "10000";
        };

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          # certificates
          "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
          "/certs/ca.crt:/certs/ca.crt:ro"

          # volumes
          "${volumes.lidarr-data.ref}:/config:U"
          "${volumes.lidarr-cache.ref}:/cache:U"

          # media volumes
          "${volumes.media-download.ref}:/download"
          "${volumes.media-music.ref}:/music"
        ];

        publishPorts = [
          "${toString ports.lidarr}:8686/tcp"
        ];
      };
    };
    */

    containers.deemix = {
      autoStart = true;

      serviceConfig = {
        Restart = "always";
        RestartSec = "10";
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.deemix}";
        name = "deemix";
        networks = [networks.media-net.ref];

        environments = {
          TZ = "Europe/Berlin";

          PUID = "0";
          PGID = "0";

          DEEMIX_SERVER_PORT = "6595";
          DEEMIX_DATA_DIR = "/config";
          DEEMIX_MUSIC_DIR = "/downloads";
        };

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          # certificates
          "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
          "/certs/ca.crt:/certs/ca.crt:ro"

          "${volumes.deemix-config.ref}:/config:U"
          "${volumes.deemix-download.ref}:/downloads:U"
        ];

        publishPorts = [
          "${toString ports.deemix}:6595/tcp"
        ];
      };
    };

    containers.slskd = {
      autoStart = true;

      unitConfig = {
        Requires = ["gluetun.service"];
        After = ["gluetun.service"];
      };

      serviceConfig = {
        Restart = "always";
        RestartSec = "10";

        ExecStartPre = [
          "+${pkgs.writeShellScript "pre-slskd" ''
            ${createSlskdConf}

            ${pkgs.coreutils}/bin/mkdir -p "${downloadPath}/slskd/finished"
            ${pkgs.coreutils}/bin/mkdir -p "${downloadPath}/slskd/incomplete"
          ''}"
        ];
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.slskd}";
        name = "slskd";
        userns = "keep-id:uid=10000,gid=10000";
        user = "10000:10000";

        networks = [
          networks.media-net.ref
          networks.vpn-service-net.ref
        ];

        environments = {
          TZ = "Europe/Berlin";

          SLSKD_REMOTE_CONFIGURATION = "false";
        };

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          # certificates
          "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
          "/certs/ca.crt:/certs/ca.crt:ro"

          # config
          "${config.home.homeDirectory}/containers/slskd/slskd.yml:/app/slskd.yml:ro"

          # volumes
          "${volumes.slskd-data.ref}:/app"

          "${volumes.slskd-download.ref}:/download"
          "${volumes.media-music.ref}:/music:ro"
        ];

        publishPorts = [
          "${toString ports.slskdHttp}:5030/tcp"
          "${toString ports.slskdHttps}:5031/tcp"
          "${toString ports.slskdPeer}:50300/tcp"
        ];
      };
    };

    containers.soularr = {
      autoStart = true;

      unitConfig = {
        Requires = [
          "lidarr.service"
          "slskd.service"
        ];

        After = [
          "lidarr.service"
          "slskd.service"
        ];
      };

      serviceConfig = {
        Restart = "always";
        RestartSec = "10";

        ExecStartPre = [
          "+${pkgs.writeShellScript "pre-soularr" ''
            ${createSoularrConf}
          ''}"

          /*
          ${pkgs.coreutils}/bin/cp ${config.home.homeDirectory}/containers/soularr/config.ini /opt/soularr/data/config.ini
          ${pkgs.coreutils}/bin/chmod 644 /opt/soularr/data/config.ini
          */
        ];
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.soularr}";
        name = "soularr";
        userns = "keep-id:uid=10000,gid=10000";
        user = "10000:10000";

        networks = [networks.media-net.ref];

        environments = {
          TZ = "Europe/Berlin";

          SCRIPT_INTERVAL = "300";
        };

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          "${volumes.soularr-data.ref}:/data"

          "${config.home.homeDirectory}/containers/soularr/config.ini:/data/config.ini:ro"
          "${volumes.slskd-download.ref}:/download"
        ];
      };
    };
  };
}
