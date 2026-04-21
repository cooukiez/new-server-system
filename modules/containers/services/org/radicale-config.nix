/*
  modules/containers/services/org/radicale-config.nix

  part of der-home-server
  created 2026-04-20
*/

{
  ports,
  ...
}:
{
  radicaleSettings = {
    server = {
      hosts = "0.0.0.0:5232";
    };

    auth = {
      type = "ldap";

      ldap_uri = "ldap://ldap.home.lan:${toString ports.lldap}";
      ldap_base = "ou=people,dc=ldap,dc=home,dc=lan";

      ldap_reader_dn = "uid=admin,ou=people,dc=ldap,dc=home,dc=lan";
      ldap_secret_file = "/run/secrets/LDAP_PASSWORD";

      ldap_filter = "(&(objectClass=person)(memberOf=cn=users,ou=groups,dc=ldap,dc=home,dc=lan)(uid={0}))";

      ldap_user_attribute = "uid";
      ldap_groups_attribute = "memberOf";

      ldap_security = "tls";
      ldap_ssl_ca_file = "/certs/ca.crt";
    };

    storage = {
      filesystem_folder = "/var/lib/radicale/collections";
    };

    logging = {
      level = "info";
    };
  };
}
