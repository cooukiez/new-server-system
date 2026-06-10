/*
modules/containers/services/opengist.nix

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
    path = "containers/opengist/env";
    vars = {
      OG_OPENGIST_HOME = "/opengist";

      OG_DB_URI = let
        name = "opengist";
        user = "admin";
        pass = "@PLACEHOLDER_DB_PASS@";

        host = "opengist-postgres";
        port = "5432";
      in "postgres://${user}:${pass}@${host}:${port}/${name}?sslmode=disable";

      OG_EXTERNAL_URL = config.myServices.opengist.serviceConfig.href;

      # authelia oidc configuration
      OG_OIDC_PROVIDER_NAME = "authelia";
      OG_OIDC_CLIENT_KEY = "opengist";
      OG_OIDC_SECRET = "@PLACEHOLDER_CLIENT_KEY@";
      OG_OIDC_DISCOVERY_URL = "https://auth.home.lan/.well-known/openid-configuration";

      OG_OIDC_GROUP_CLAIM_NAME = "groups";
      OG_OIDC_ADMIN_GROUP = "admins";
    };

    secrets = {
      PLACEHOLDER_CLIENT_KEY = config.age.secrets.opengist-client-key.path;
      PLACEHOLDER_DB_PASS = config.age.secrets.opengist-db-pass.path;
    };
  };
in {
  myServices.opengist = {
    serviceConfig = {
      name = "Opengist";
      description = "Unstructured Code Storage";
      serviceType = "Apps";

      subdomain = "gists";
      port = ports.opengistHttp;

      policy = "bypass";

      icon = "opengist";
    };
  };

  age.secrets = let
    mkSecret = name: {
      file = ../../../secrets/containers/opengist/${name}.age;
    };
  in {
    opengist-client-key = mkSecret "s_auth-client";
    opengist-db-pass = mkSecret "s_db-pass";
  };

  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) volumes networks;
  in {
    networks.opengist-net = {
      networkConfig = {
        internal = false;
      };
    };

    volumes.opengist-db.volumeConfig = {
      type = "bind";
      device = "/opt/opengist/db";
    };

    volumes.opengist-data.volumeConfig = {
      type = "bind";
      device = "/opt/opengist/data";
    };

    containers.opengist-postgres = {
      autoStart = true;
      serviceConfig = {
        Restart = "always";
        RestartSec = "10";
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.postgres}";
        name = "opengist-postgres";
        networks = [networks.opengist-net.ref networks.postgres-net.ref];

        environments = {
          POSTGRES_USER = "admin";
          POSTGRES_PASSWORD_FILE = "/run/secrets/OPENGIST_DB_PASS";

          POSTGRES_DB = "opengist";
        };

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          "${volumes.opengist-db.ref}:/var/lib/postgresql:U"
          "${config.age.secrets.opengist-db-pass.path}:/run/secrets/OPENGIST_DB_PASS:ro"
        ];
      };
    };

    containers.opengist = {
      autoStart = true;

      unitConfig = {
        Requires = ["opengist-postgres.service"];
        After = ["opengist-postgres.service"];
      };

      serviceConfig = {
        Restart = "always";
        RestartSec = "10";

        ExecStartPre = [
          "+${pkgs.writeShellScript "pre-opengist" ''
            ${createEnv}
          ''}"
        ];
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.opengist}";
        name = "opengist";
        user = "0:0";
        networks = [networks.opengist-net.ref];

        addHosts = [
          "auth.home.lan:host-gateway"
        ];

        environments = {
          TZ = "Europe/Berlin";

          UID = "0";
          GID = "0";
        };

        environmentFiles = [
          "env/containers/opengist/env"
        ];

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          # certificates
          "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
          "/certs/ca.crt:/certs/ca.crt:ro"

          "${volumes.opengist-data.ref}:/opengist:U"
        ];

        publishPorts = [
          "${toString ports.opengist}:2222/tcp"
          "${toString ports.opengistHttp}:6157/tcp"
        ];
      };
    };
  };
}
