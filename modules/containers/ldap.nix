/*
  modules/containers/ldap.nix

  part of der-home-server
  created 2026-04-14
*/

{
  config,
  pkgs,
  ports,
  ...
}:
let
  lldapVersion = "stable";
in
{
  age.secrets = {
    lldap-jwt.file = ../../secrets/ldap/s_jwt-secret.age;
    lldap-seed.file = ../../secrets/ldap/s_key-seed.age;
    lldap-admin.file = ../../secrets/ldap/s_admin-pass.age;

    postgres-pw.file = ../../secrets/s_postgres-pw.age;
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes;
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
        };

        containerConfig = {
          image = "docker.io/lldap/lldap:${lldapVersion}";
          name = "lldap";
          user = "0:0";
          networks = [ "auth-net" ];

          environments = {
            TZ = "Europe/Berlin";

            UID = "0";
            GID = "0";

            # settings
            LLDAP_LDAP_BASE_DN = "dc=ldap,dc=home,dc=lan";

            LLDAP_JWT_SECRET_FILE = "/run/secrets/LLDAP_JWT_SECRET";
            LLDAP_KEY_SEED_FILE = "/run/secrets/LLDAP_KEY_SEED";
            LLDAP_LDAP_USER_PASS_FILE = "/run/secrets/LLDAP_ADMIN_PASS";

            LLDAP_KEY_FILE = "";

            LLDAP_DATABASE_URL = "postgres://lldap:lldap@host.containers.internal:${toString ports.postgres}/lldap";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/certs/home.lan.crt:/usr/local/share/ca-certificates/home.lan.crt:ro"
            "/certs/home.lan.crt:/certs/home.lan.crt:ro"

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
