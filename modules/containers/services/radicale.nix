/*
  modules/containers/services/node-red.nix
  Created: 2026-04-15
*/

{
  config,
  pkgs,
  ports,
  envSecretsPrefix,
  ...
}:
let
  settingsFormat = pkgs.formats.yaml { };

  radicaleVersion = "3.5.4";

  # radicale settings
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
      ldap_ssl_ca_file = "/certs/home.lan.crt";
    };

    storage = {
      type = "filesystem";
      filesystem_folder = "/var/lib/radicale/collections";
    };
    
    logging = {
      level = "info";
    };
  };
in
{
  home.file."containers/radicale/config" = {
    source = settingsFormat.generate "config" radicaleSettings;
  };

  age.secrets =
    let
      mkSecret = name: {
        file = ../../../secrets/${name}.age;
        path = "${envSecretsPrefix}/${name}";
      };
    in
    {
      radicale-ldap-pw = mkSecret "ldap/admin-pass";
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes;
    in
    {
      volumes.radicale-config.volumeConfig = {
        type = "bind";
        device = "/opt/radicale/config";
      };

      volumes.radicale-data.volumeConfig = {
        type = "bind";
        device = "/opt/radicale/data";
      };

      containers.radicale = {
        autoStart = true;

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "ghcr.io/kozea/radicale:${radicaleVersion}";
          name = "radicale";
          user = "0:0";

          addHosts = [
            "ldap.home.lan:host-gateway"
            "git.home.lan:host-gateway"
          ];

          environments = {
            RADICALE_CONFIG = "/etc/radicale/config";
            
            GIT_SSL_CAINFO = "/certs/home.lan.crt";
          };

          volumes = [
            # config
            "${config.home.homeDirectory}/containers/radicale/config:/etc/radicale/config:ro"

            # secrets
            "${config.age.secrets.radicale-ldap-pw.path}:/run/secrets/LDAP_PASSWORD:ro"

            # certificates
            "/certs/home.lan.crt:/usr/local/share/ca-certificates/home.lan.crt:ro"
            "/certs/home.lan.crt:/certs/home.lan.crt:ro"

            # volumes
            "${volumes.radicale-config.ref}:/etc/radicale:ro"
            "${volumes.radicale-data.ref}:/var/lib/radicale"
          ];

          publishPorts = [
            "${toString ports.radicale}:5232/tcp"
          ];
        };
      };
    };
}