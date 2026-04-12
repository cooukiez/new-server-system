/*
  modules/containers/lldap.nix

  part of der-home-server
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
    lldap-jwt.file = ../../secrets/ldap/jwt-secret.age;
    lldap-seed.file = ../../secrets/ldap/key-seed.age;
    lldap-admin.file = ../../secrets/ldap/admin-pass.age;

    postgres-pw.file = ../../secrets/postgres-pw.age;
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
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/lldap/lldap:${lldapVersion}";
          name = "lldap";

          environments = {
            LLDAP_LDAP_BASE_DN = "dc=example,dc=com";
            TZ = "Europe/Berlin";

            LLDAP_JWT_SECRET_FILE = "/run/secrets/LLDAP_JWT_SECRET";
            LLDAP_KEY_SEED_FILE = "/run/secrets/LLDAP_KEY_SEED";
            LLDAP_LDAP_USER_PASS_FILE = "/run/secrets/LLDAP_ADMIN_PASS";

            LLDAP_DATABASE_URL = "postgres://lldap@host.containers.internal:5432/lldap";
          };

          volumes = [
            "${config.age.secrets.lldap-jwt-secret.path}:/run/secrets/LLDAP_JWT_SECRET:ro"
            "${config.age.secrets.lldap-key-seed.path}:/run/secrets/LLDAP_KEY_SEED:ro"
            "${config.age.secrets.lldap-admin-pass.path}:/run/secrets/LLDAP_ADMIN_PASS:ro"

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
