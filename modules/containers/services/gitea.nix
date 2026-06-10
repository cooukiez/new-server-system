/*
modules/containers/services/gitea.nix

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
    path = "containers/gitea/env";
    vars = {
      GITEA__database__DB_TYPE = "postgres";
      GITEA__database__HOST = "gitea-postgres:5432";
      GITEA__database__NAME = "gitea";
      GITEA__database__USER = "admin";
      GITEA__database__PASSWD = "@PLACEHOLDER_DB_PASS@";
    };

    secrets = {
      PLACEHOLDER_DB_PASS = config.age.secrets.gitea-db-pass.path;
    };

    mode = "644";
  };
in {
  myServices.gitea = {
    serviceConfig = {
      name = "Gitea";
      description = "Selfhosted DevOps Platform";
      serviceType = "Apps";

      subdomain = "git";
      port = ports.giteaHttp;

      policy = "bypass";

      icon = "gitea";
    };
  };

  age.secrets = let
    mkSecret = name: {
      file = ../../../secrets/containers/gitea/${name}.age;
    };
  in {
    gitea-db-pass = mkSecret "s_db-pass";
  };

  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) volumes networks;
  in {
    networks.gitea-net = {
      networkConfig = {
        internal = false;
      };
    };

    volumes.gitea-db.volumeConfig = {
      type = "bind";
      device = "/opt/gitea/db";
    };

    volumes.gitea-data.volumeConfig = {
      type = "bind";
      device = "/opt/gitea/data";
    };


    containers.gitea-postgres = {
      autoStart = true;
      serviceConfig = {
        Restart = "always";
        RestartSec = "10";
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.postgres}";
        name = "gitea-postgres";
        networks = [networks.gitea-net.ref networks.postgres-net.ref];

        environments = {
          POSTGRES_USER = "admin";
          POSTGRES_PASSWORD_FILE = "/run/secrets/GITEA_DB_PASS";

          POSTGRES_DB = "gitea";
        };

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          "${volumes.gitea-db.ref}:/var/lib/postgresql:U"
          "${config.age.secrets.gitea-db-pass.path}:/run/secrets/GITEA_DB_PASS:ro"
        ];
      };
    };


    containers.gitea = {
      autoStart = true;

      unitConfig = {
        Requires = ["gitea-postgres.service"];
        After = ["gitea-postgres.service"];
      };

      serviceConfig = {
        Restart = "always";
        RestartSec = "10";

        ExecStartPre = [
          "+${pkgs.writeShellScript "pre-gitea" ''
            ${createEnv}
          ''}"
        ];
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.gitea}";
        name = "gitea";
        networks = [networks.gitea-net.ref];

        addHosts = [
          "auth.home.lan:host-gateway"
        ];

        environments = {
          TZ = "Europe/Berlin";
        };

        environmentFiles = [
          "env/containers/gitea/env"
        ];

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          # certificates
          "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
          "/certs/ca.crt:/certs/ca.crt:ro"

          # volumes
          "${volumes.gitea-data.ref}:/data:U"
        ];

        publishPorts = [
          "${toString ports.giteaHttp}:3000/tcp"
          "${toString ports.gitea}:22/tcp"
        ];
      };
    };
  };
}
