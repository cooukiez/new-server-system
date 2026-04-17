/*
  modules/containers/auth.nix

  part of der-home-server
  created 2026-04-14
*/

{
  config,
  pkgs,
  lib,
  ports,
  autheliaRules,
  ...
}:
let
  settingsFormat = pkgs.formats.yaml { };

  autheliaVersion = "latest";
  autheliaSettings = {
    theme = "dark";

    server = {
      address = "tcp://0.0.0.0:9091";
    };

    log = {
      level = "info";
    };

    authentication_backend = {
      refresh_interval = "1m";
      ldap = {
        implementation = "lldap";
        address = "ldap://lldap:3890";
        base_dn = "dc=ldap,dc=home,dc=lan";
        user = "uid=admin,ou=people,dc=ldap,dc=home,dc=lan";
      };
    };

    access_control = {
      default_policy = "deny";
      rules = autheliaRules;
    };

    session = {
      name = "authelia_session";
      cookies = [
        {
          domain = "home.lan";
          authelia_url = "https://auth.home.lan";
          default_redirection_url = "https://home.lan";
        }
      ];
      expiration = "1h";
      inactivity = "5m";
    };

    identity_providers = {
      oidc = {
        jwks = [
          {
            key_id = "main-rsa";
            algorithm = "RS256";
            use = "sig";

            key = "PLACEHOLDER_AUTH_OIDC_KEY";
          }
        ];

        claims_policies = {
          grafana = {
            id_token = [
              "email"
              "name"
              "groups"
              "preferred_username"
            ];
          };
        };

        clients = import ./auth/oidc-clients.nix;
      };
    };

    storage = {
      postgres = {
        address = "tcp://host.containers.internal:${toString ports.postgres}";
        database = "authelia";
        username = "admin";
      };
    };

    notifier = {
      smtp = {
        address = "smtp.mailbox.org:587";
        sender = "ludwig.geyer@mailbox.org";
        username = "ludwig.geyer@mailbox.org";
      };
    };
  };

  # secret mappings
  secretMap = {
    auth-ldap-pw = "ldap/s_admin-pass";

    auth-jwt = "auth/s_jwt-secret";
    auth-session = "auth/s_session";

    auth-postgres-pw = "s_postgres-pw";
    auth-storage-key = "auth/s_storage-key";

    auth-oidc-hmac = "auth/s_oidc-hmac";
    auth-oidc-jwk = "auth/s_oidc-jwk";

    auth-mail-smtp = "auth/s_mail-smtp";
  };

  secretMounts = {
    auth-ldap-pw = "AUTH_LDAP_PASSWORD";
    auth-jwt = "AUTH_JWT_SECRET";
    auth-session = "AUTH_SESSION_SECRET";
    auth-postgres-pw = "AUTH_POSTGRES_PASSWORD";
    auth-storage-key = "AUTH_STORAGE_KEY";
    auth-oidc-hmac = "AUTH_OIDC_HMAC_SECRET";
    auth-oidc-jwk = "AUTH_OIDC_JWK_KEY";
    auth-mail-smtp = "AUTH_MAIL_SMTP_PW";
  };

  envMapping = {
    auth-ldap-pw = "AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE";
    auth-jwt = "AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE";
    auth-session = "AUTHELIA_SESSION_SECRET_FILE";
    auth-postgres-pw = "AUTHELIA_STORAGE_POSTGRES_PASSWORD_FILE";
    auth-storage-key = "AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE";
    auth-oidc-hmac = "AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET_FILE";
    auth-mail-smtp = "AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE";
  };
in
{
  imports = [
    ./auth/users.nix
  ];

  home.file."containers/authelia/configuration.yml" = {
    source = settingsFormat.generate "configuration.yml" autheliaSettings;
  };

  age.secrets = builtins.mapAttrs (_: name: {
    file = ../../secrets/${name}.age;
  }) secretMap;

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      networks.auth-net = {
        networkConfig = {
          internal = false;
        };
      };

      volumes.authelia-config.volumeConfig = {
        type = "bind";
        device = "/opt/authelia/config";
      };

      containers.authelia = {
        autoStart = true;

        unitConfig = {
          Requires = [ "postgres.service" ];
          After = [ "postgres.service" ];
        };

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";

          ExecStartPre = [
            "${pkgs.coreutils}/bin/cp ${config.home.homeDirectory}/containers/authelia/configuration.yml /opt/authelia/config/configuration.yml"
            "${pkgs.coreutils}/bin/cp ${config.home.homeDirectory}/containers/authelia/users.yml /opt/authelia/config/users.yml"

            "${pkgs.yq-go}/bin/yq -i '.identity_providers.oidc.jwks[0].key = load_str(\"${config.age.secrets.auth-oidc-jwk.path}\")' /opt/authelia/config/configuration.yml"

            "${pkgs.coreutils}/bin/chmod 644 /opt/authelia/config/configuration.yml"
            "${pkgs.coreutils}/bin/chmod 644 /opt/authelia/config/users.yml"
          ];
        };

        containerConfig = {
          image = "ghcr.io/authelia/authelia:${autheliaVersion}";
          name = "authelia";
          networks = [ "auth-net" ];

          volumes =
            (lib.mapAttrsToList (
              name: mount: "${config.age.secrets.${name}.path}:/run/secrets/${mount}:ro"
            ) secretMounts)
            ++ [
              "/etc/timezone:/etc/timezone:ro"
              "/etc/localtime:/etc/localtime:ro"

              # certificates
              "/certs/ca.crt:/usr/local/share/ca-certificates/ca.crt:ro"
              "/certs/ca.crt:/certs/ca.crt:ro"

              "${volumes.authelia-config.ref}:/config:U"
            ];

          environments =
            (lib.mapAttrs' (name: envVar: {
              name = envVar;
              value = "/run/secrets/${secretMounts.${name}}";
            }) envMapping)
            // {
              TZ = "Europe/Berlin";
            };

          publishPorts = [
            "${toString ports.authelia}:9091/tcp"
          ];
        };
      };
    };
}
