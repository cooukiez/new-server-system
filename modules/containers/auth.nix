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
  ...
}:
let
  autheliaVersion = "latest";

  publicServices = lib.filterAttrs (_: svc: svc.serviceConfig != { }) config.myServices;
  sortedServiceList = lib.sort (a: b: a.serviceConfig.subdomain < b.serviceConfig.subdomain) (
    lib.attrValues publicServices
  );

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
      rules = [
        {
          domain = "auth.home.lan";
          policy = "bypass";
        }
        {
          domain = "ldap.home.lan";
          policy = "bypass";
        }
        {
          domain = "home.lan";
          policy = "bypass";
        }
      ]
      ++ (lib.mapAttrsToList (
        svc:
        let
          cfg = svc.serviceConfig;
        in
        {
          domain = "${cfg.subdomain}.home.lan";
          policy = cfg.policy;
        }
        // (lib.optionalAttrs (cfg.group != null) {
          subject = [ "group:${cfg.group}" ];
        })
      ) sortedServiceList);
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
  myServices.authelia = {
    serviceConfig = {
      description = "OpenID Authentication System";
      serviceType = "Apps";

      subdomain = "auth";
      port = ports.authelia;

      policy = "bypass";

      icon = "authelia";
    };

    containerConfig = {
      files."configuration.yml" = {
        source = (pkgs.formats.yaml { }).generate "configuration.yml" autheliaSettings;
      };

      volumes = {
        authelia-config = "/opt/authelia/config";
      };
    };
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
        device = config.myServices.authelia.containerConfig.volumes.authelia-config;
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
            "${pkgs.coreutils}/bin/cp ${
              config.myServices.authelia.containerConfig.files."configuration.yml".fullPath
            }/ /opt/authelia/config/configuration.yml"
            "${pkgs.yq-go}/bin/yq -i '.identity_providers.oidc.jwks[0].key = load_str(\"${config.age.secrets.auth-oidc-jwk.path}\")' /opt/authelia/config/configuration.yml"
            "${pkgs.coreutils}/bin/chmod 644 /opt/authelia/config/configuration.yml"
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
