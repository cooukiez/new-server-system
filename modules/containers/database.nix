/*
modules/containers/database.nix

part of server system
created 2026-04-20
*/
{
  config,
  pkgs,
  images,
  ports,
  mkConf,
  ...
}: let
  services = [
    {
      name = "authelia";
      user = "admin";
      dbs = ["authelia"];
    }
    {
      name = "lldap";
      user = "lldap";
      dbs = ["lldap"];
      pass = "@PLACEHOLDER_LLDAP_DB_PASS@";
    }

    {
      name = "atuin";
      user = "atuin";
      dbs = ["atuin"];
      pass = "@PLACEHOLDER_ATUIN_DB_PASS@";
    }
    {
      name = "ebk";
      user = "ebk";
      dbs = ["ebk"];
      pass = "@PLACEHOLDER_EBK_DB_PASS@";
    }
    {
      name = "gitea";
      user = "gitea";
      dbs = ["gitea"];
      pass = "@PLACEHOLDER_GITEA_DB_PASS@";
    }
    {
      name = "linkwarden";
      user = "linkwarden";
      dbs = ["linkwarden"];
      pass = "@PLACEHOLDER_LINK_DB_PASS@";
    }
    {
      name = "mail-archiver";
      user = "archiver";
      dbs = ["mail-archiver"];
      pass = "@PLACEHOLDER_ARCHIVER_DB_PASS@";
    }
    {
      name = "memos";
      user = "memos";
      dbs = ["memos"];
      pass = "@PLACEHOLDER_MEMOS_DB_PASS@";
    }
    {
      name = "opengist";
      user = "opengist";
      dbs = ["opengist"];
      pass = "@PLACEHOLDER_OPENGIST_DB_PASS@";
    }
    {
      name = "outline";
      user = "outline";
      dbs = ["outline"];
      pass = "@PLACEHOLDER_OUTLINE_DB_PASS@";
    }

    {
      name = "lidarr";
      user = "lidarr";
      dbs = [
        "lidarr-main"
        "lidarr-log"
      ];
      pass = "@PLACEHOLDER_LIDARR_DB_PASS@";
    }
  ];

  mkSql = service: ''
    -- Configuration for ${service.name}
    ${
      if service ? pass
      then ''
        DO $$ 
        BEGIN
          IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${service.user}') THEN
            CREATE USER ${service.user} WITH PASSWORD '${service.pass}';
          ELSE
            ALTER USER ${service.user} WITH PASSWORD '${service.pass}';
          END IF;
        END $$;''
      else ""
    }

    ${builtins.concatStringsSep "\n" (
      map (db: ''
        -- Database: ${db}
        SELECT 'CREATE DATABASE "${db}"' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${db}')\gexec
        ALTER DATABASE "${db}" OWNER TO ${service.user};
        GRANT ALL PRIVILEGES ON DATABASE "${db}" TO admin;
      '')
      service.dbs
    )}
  '';

  createConf = mkConf {
    path = "containers/postgres/init-all-db.sql";
    source = pkgs.writeText "init-all-db-template" ''
      \set ON_ERROR_STOP off

      ${builtins.concatStringsSep "\n" (map mkSql services)}
    '';

    secrets = {
      PLACEHOLDER_LLDAP_DB_PASS = config.age.secrets.postgres-lldap-db-pass.path;

      PLACEHOLDER_ATUIN_DB_PASS = config.age.secrets.postgres-atuin-db-pass.path;
      PLACEHOLDER_EBK_DB_PASS = config.age.secrets.postgres-ebk-db-pass.path;
      PLACEHOLDER_GITEA_DB_PASS = config.age.secrets.postgres-gitea-db-pass.path;
      PLACEHOLDER_LINK_DB_PASS = config.age.secrets.postgres-link-db-pass.path;
      PLACEHOLDER_ARCHIVER_DB_PASS = config.age.secrets.postgres-archiver-db-pass.path;
      PLACEHOLDER_MEMOS_DB_PASS = config.age.secrets.postgres-memos-db-pass.path;
      PLACEHOLDER_OPENGIST_DB_PASS = config.age.secrets.postgres-opengist-db-pass.path;
      PLACEHOLDER_OUTLINE_DB_PASS = config.age.secrets.postgres-outline-db-pass.path;
      PLACEHOLDER_LIDARR_DB_PASS = config.age.secrets.postgres-lidarr-db-pass.path;
    };

    mode = "644";
  };
in {
  myServices.postgres = {
    serviceConfig = {
      name = "Postgres DB";
      description = "Centralized Relational Database";
      serviceType = "Services";

      subdomain = "db";
      port = ports.pgadmin;

      policy = "bypass";

      icon = "postgresql";
    };
  };

  age.secrets = let
    mkSecret = name: {
      file = ../../secrets/${name}.age;
      mode = "444";
    };
  in {
    postgres-lldap-db-pass = mkSecret "auth/ldap/s_db-pass";

    postgres-atuin-db-pass = mkSecret "containers/atuin/s_db-pass";
    postgres-ebk-db-pass = mkSecret "containers/ebk/s_db-pass";
    postgres-gitea-db-pass = mkSecret "containers/gitea/s_db-pass";
    postgres-link-db-pass = mkSecret "containers/link/s_db-pass";
    postgres-archiver-db-pass = mkSecret "containers/archiver/s_db-pass";
    postgres-memos-db-pass = mkSecret "containers/memos/s_db-pass";
    postgres-opengist-db-pass = mkSecret "containers/opengist/s_db-pass";
    postgres-outline-db-pass = mkSecret "containers/outline/s_db-pass";
    postgres-lidarr-db-pass = mkSecret "containers/lidarr/s_db-pass";

    postgres-pw = mkSecret "db/s_postgres-pw";
    pgadmin-pw = mkSecret "db/s_pgadmin-pw";
  };

  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) volumes networks pods;
  in {
    networks.postgres-net = {
      networkConfig = {
        internal = false;
      };
    };

    volumes.postgres-data.volumeConfig = {
      type = "bind";
      device = "/opt/postgres/data";
    };

    volumes.pgadmin-data.volumeConfig = {
      type = "bind";
      device = "/opt/postgres/pgadmin";
    };

    containers.postgres = {
      autoStart = true;
      serviceConfig = {
        Restart = "always";
        RestartSec = "10";

        ExecStartPre = [
          "+${pkgs.writeShellScript "pre-postgres" ''
            ${createConf}
          ''}"
        ];
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.postgres}";
        name = "postgres";
        networks = ["postgres-net"];

        environments = {
          TZ = "Europe/Berlin";

          POSTGRES_USER = "admin";
          POSTGRES_PASSWORD_FILE = "/run/secrets/POSTGRES_PASSWORD";

          POSTGRES_DB = "app_db";
        };

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          # certificates
          "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
          "/certs/ca.crt:/certs/ca.crt:ro"

          # secrets
          "${config.age.secrets.postgres-pw.path}:/run/secrets/POSTGRES_PASSWORD:ro"

          # volumes
          "${volumes.postgres-data.ref}:/var/lib/postgresql:U"

          # startup scripts
          "${config.home.homeDirectory}/containers/postgres/init-all-db.sql:/docker-entrypoint-initdb.d/init-all-db.sql:ro,U"
        ];

        publishPorts = [
          "${toString ports.postgres}:5432/tcp"
        ];
      };
    };

    containers.pgadmin = {
      autoStart = true;
      serviceConfig = {
        Restart = "always";
        RestartSec = "10";
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.pgadmin}";
        name = "pgadmin";
        networks = ["postgres-net"];

        environments = {
          TZ = "Europe/Berlin";

          PGADMIN_DEFAULT_EMAIL = "management.homeserver@mailbox.org";
          PGADMIN_DEFAULT_PASSWORD_FILE = "/run/secrets/PGADMIN_PASSWORD";

          PGADMIN_CONFIG_ENHANCED_COOKIE_PROTECTION = "True";
          PGADMIN_CONFIG_CONSOLE_LOG_LEVEL = "10";

          PGADMIN_LISTEN_ADDRESS = "0.0.0.0";
          PGADMIN_LISTEN_PORT = "80";
        };

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          # certificates
          "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
          "/certs/ca.crt:/certs/ca.crt:ro"

          # secrets
          "${config.age.secrets.pgadmin-pw.path}:/run/secrets/PGADMIN_PASSWORD:ro"

          # volumes
          "${volumes.pgadmin-data.ref}:/var/lib/pgadmin:U"
        ];

        publishPorts = [
          "${toString ports.pgadmin}:80/tcp"
        ];
      };
    };
  };
}
