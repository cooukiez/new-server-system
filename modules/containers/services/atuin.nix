/*
modules/containers/services/atuin.nix

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
    path = "containers/atuin/env";
    vars = {
      ATUIN_HOST = "0.0.0.0";
      ATUIN_PORT = "8888";

      ATUIN_OPEN_REGISTRATION = "true";

      ATUIN_DB_URI = let
        name = "atuin";
        user = "admin";
        pass = "@PLACEHOLDER_DB_PASS@";

        host = "atuin-postgres";
        port = "5432";
      in "postgres://${user}:${pass}@${host}:${port}/${name}?sslmode=disable";

      RUST_LOG = "info,atuin_server=debug";
    };

    secrets = {
      PLACEHOLDER_DB_PASS = config.age.secrets.atuin-db-pass.path;
    };
  };
in {
  myServices.atuin = {
    serviceConfig = {
      name = "Atuin";
      description = "Syncing Shell History";
      serviceType = "Apps";

      subdomain = "atuin";
      port = ports.atuin;

      policy = "bypass";

      icon = "atuin";
    };
  };

  age.secrets = let
    mkSecret = name: {
      file = ../../../secrets/containers/atuin/${name}.age;
    };
  in {
    atuin-db-pass = mkSecret "s_db-pass";
  };

  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) volumes networks;
  in {
    networks.atuin-net = {
      networkConfig = {
        internal = false;
      };
    };

    volumes.atuin-config.volumeConfig = {
      type = "bind";
      device = "/opt/atuin/config";
    };

    volumes.atuin-db.volumeConfig = {
      type = "bind";
      device = "/opt/atuin/db";
    };

    containers.atuin-postgres = {
      autoStart = true;
      serviceConfig = {
        Restart = "always";
        RestartSec = "10";
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.postgres}";
        name = "atuin-postgres";
        networks = [networks.atuin-net.ref networks.postgres-net.ref];

        environments = {
          POSTGRES_USER = "admin";
          POSTGRES_PASSWORD_FILE = "/run/secrets/ATUIN_DB_PASS";

          POSTGRES_DB = "atuin";
        };

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          "${volumes.atuin-db.ref}:/var/lib/postgresql:U"
          "${config.age.secrets.atuin-db-pass.path}:/run/secrets/ATUIN_DB_PASS:ro"
        ];
      };
    };

    containers.atuin = {
      autoStart = true;

      unitConfig = {
        Requires = ["postgres.service"];
        After = ["postgres.service"];
      };

      serviceConfig = {
        Restart = "always";
        RestartSec = "10";

        ExecStartPre = [
          "+${pkgs.writeShellScript "pre-atuin" ''
            ${createEnv}
          ''}"
        ];
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.atuin}";
        name = "atuin";
        networks = [networks.atuin-net.ref];

        exec = ["start"];

        environments = {
          TZ = "Europe/Berlin";
        };

        environmentFiles = [
          "env/containers/atuin/env"
        ];

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          # certificates
          "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
          "/certs/ca.crt:/certs/ca.crt:ro"

          "${volumes.atuin-config.ref}:/config:U"
        ];

        publishPorts = [
          "${toString ports.atuin}:8888/tcp"
        ];
      };
    };
  };
}
