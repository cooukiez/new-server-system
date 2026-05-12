/*
  modules/containers/ldap.nix

  part of der-home-server
  created 2026-04-14
*/

{
  config,
  pkgs,
  images,
  ports,
  ...
}:

let
  createEnv = mkEnv {
    path = "containers/lldap/env";
    vars = {
      LLDAP_LDAP_BASE_DN = "dc=ldap,dc=home,dc=lan";

      LLDAP_JWT_SECRET_FILE = "/run/secrets/LLDAP_JWT_SECRET";
      LLDAP_KEY_SEED_FILE = "/run/secrets/LLDAP_KEY_SEED";
      LLDAP_LDAP_USER_PASS_FILE = "/run/secrets/LLDAP_ADMIN_PASS";

      LLDAP_KEY_FILE = "";

      LLDAP_DATABASE_URL =
        let
          name = "lldap";
          user = "lldap";
          pass = "@PLACEHOLDER_DB_PASS@";

          host = "host.containers.internal";
          port = toString ports.postgres;
        in
        "postgres://${user}:${pass}@${host}:${port}/${name}";
    };

    secrets = {
      # "PLACEHOLDER_DB_PASS" = config.age.secrets.lldap-db-pass.path;
      "PLACEHOLDER_DB_PASS" = pkgs.writeText "db-pass" "lldap";
    };
  };
in
{
  myServices.lldap = {
    serviceConfig = {
      name = "LLDAP";
      description = "Global User Management";
      serviceType = "Services";

      subdomain = "ldap";
      port = ports.lldap;

      policy = "bypass";

      icon = "https://avatars.githubusercontent.com/u/129409591?s=48&v=4";
    };
  };

  age.secrets =
    let
      mkSecret = name: {
        file = ../../secrets/${name}.age;
      };
    in
    {
      lldap-admin = mkSecret "auth/ldap/s_admin-pass";
      lldap-db-pass = mkSecret "auth/ldap/s_db-pass";
      lldap-jwt = mkSecret "auth/ldap/s_jwt-secret";
      lldap-seed = mkSecret "auth/ldap/s_key-seed";

      ldap-postgres-pw = mkSecret "db/s_postgres-pw";
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.lldap-data.volumeConfig = {
        type = "bind";
        device = "/opt/lldap/data";
      };

      containers.lldap = {
        autoStart = true;

        unitConfig = {
          Requires = [ "postgres.service" ];
          After = [ "postgres.service" ];
        };

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";

          ExecStartPre = [
            "+${pkgs.writeShellScript "pre-lldap" ''
              ${createEnv}
            ''}"
          ];
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.lldap}";
          name = "lldap";
          networks = [ "auth-net" ];

          environments = {
            TZ = "Europe/Berlin";

            UID = "0";
            GID = "0";
          };

          environmentFiles = [
            "env/containers/lldap/env"
          ];

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            # secrets
            "${config.age.secrets.lldap-jwt.path}:/run/secrets/LLDAP_JWT_SECRET:ro"
            "${config.age.secrets.lldap-seed.path}:/run/secrets/LLDAP_KEY_SEED:ro"
            "${config.age.secrets.lldap-admin.path}:/run/secrets/LLDAP_ADMIN_PASS:ro"

            # volumes
            "${volumes.lldap-data.ref}:/data"
          ];

          publishPorts = [
            "${toString ports.lldap}:3890/tcp"
            "${toString ports.lldapWeb}:17170/tcp"
          ];
        };
      };
    };
}
