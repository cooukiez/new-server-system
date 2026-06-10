/*
modules/containers/services/memos.nix

part of server system
created 2026-05-13 by ludw
*/
{
  config,
  pkgs,
  images,
  ports,
  mkEnv,
  ...
}: let
  createEnv = mkEnv {
    path = "containers/memos/env";
    vars = {
      MEMOS_DRIVER = "postgres";
      MEMOS_DSN = let
        name = "memos";
        user = "admin";
        pass = "@PLACEHOLDER_DB_PASS@";

        host = "memos-postgres";
        port = "5432";
      in "postgres://${user}:${pass}@${host}:${port}/${name}?sslmode=disable";

      MEMOS_ADDR = "0.0.0.0";
      MEMOS_PORT = "5230";

      MEMOS_INSTANCE_URL = config.myServices.memos.serviceConfig.href;

      MEMOS_DATA = "/data";
    };

    secrets = {
      PLACEHOLDER_DB_PASS = config.age.secrets.memos-db-pass.path;
    };
  };
in {
  myServices.memos = {
    serviceConfig = {
      name = "Memos";
      description = "Lightweight Note-Taking Service";
      serviceType = "Apps";

      subdomain = "memos";
      port = ports.memos;

      policy = "bypass";

      icon = "memos";
    };
  };

  age.secrets = let
    mkSecret = name: {
      file = ../../../secrets/containers/memos/${name}.age;
    };
  in {
    memos-db-pass = mkSecret "s_db-pass";
  };

  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) volumes networks;
  in {
    networks.memos-net = {
      networkConfig = {
        internal = false;
      };
    };

    volumes.memos-db.volumeConfig = {
      type = "bind";
      device = "/opt/memos/db";
    };

    volumes.memos-data.volumeConfig = {
      type = "bind";
      device = "/opt/memos/data";
    };

    containers.memos-postgres = {
      autoStart = true;
      serviceConfig = {
        Restart = "always";
        RestartSec = "10";
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.postgres}";
        name = "memos-postgres";
        networks = [networks.memos-net.ref networks.postgres-net.ref];

        environments = {
          POSTGRES_USER = "admin";
          POSTGRES_PASSWORD_FILE = "/run/secrets/MEMOS_DB_PASS";

          POSTGRES_DB = "memos";
        };

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          "${volumes.memos-db.ref}:/var/lib/postgresql:U"
          "${config.age.secrets.memos-db-pass.path}:/run/secrets/MEMOS_DB_PASS:ro"
        ];
      };
    };

    containers.memos = {
      autoStart = true;

      unitConfig = {
        Requires = ["memos-postgres.service"];
        After = ["memos-postgres.service"];
      };

      serviceConfig = {
        Restart = "always";
        RestartSec = "10";

        ExecStartPre = [
          "+${pkgs.writeShellScript "pre-memos" ''
            ${createEnv}
          ''}"
        ];
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.memos}";
        name = "memos";
        networks = [networks.memos-net.ref];

        addHosts = [
          "auth.home.lan:host-gateway"
        ];

        environments = {
          TZ = "Europe/Berlin";
        };

        environmentFiles = [
          "env/containers/memos/env"
        ];

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          # certificates
          "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
          "/certs/ca.crt:/certs/ca.crt:ro"

          "${volumes.memos-data.ref}:/data:U"
        ];

        publishPorts = [
          "${toString ports.memos}:5230/tcp"
        ];
      };
    };
  };
}
