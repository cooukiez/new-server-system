/*
  modules/containers/auth.nix

  part of der-home-server
  created 2026-04-10
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
      file = {
        path = "/config/users.yml";
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
        address = "tcp://host.containers.internal:5432";
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
    auth-jwt-key = "auth/jwt-key";
    auth-session = "auth/session";

    auth-storage-pw = "postgres-pw";
    auth-storage-key = "auth/storage-key";

    auth-oidc-hmac = "auth/oidc-hmac";
    auth-oidc-jwk = "auth/oidc-jwk";

    auth-mail-smtp = "auth/mail-smtp";
  };

  secretMounts = {
    auth-jwt-key = "AUTH_JWT_KEY";
    auth-session = "AUTH_SESSION_SECRET";
    auth-storage-pw = "AUTH_STORAGE_PASSWORD";
    auth-storage-key = "AUTH_STORAGE_KEY";
    auth-oidc-hmac = "AUTH_OIDC_HMAC_SECRET";
    auth-oidc-jwk = "AUTH_OIDC_JWK_KEY";
    auth-mail-smtp = "AUTH_MAIL_SMTP_PW";
  };

  envMapping = {
    auth-jwt-key = "AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE";
    auth-session = "AUTHELIA_SESSION_SECRET_FILE";
    auth-storage-pw = "AUTHELIA_STORAGE_POSTGRES_PASSWORD_FILE";
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
      volumes.authelia-config.volumeConfig = {
        type = "bind";
        device = "/opt/authelia/config";
      };

      containers.authelia = {
        autoStart = true;
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
          image = "docker.io/authelia/authelia:${autheliaVersion}";
          name = "authelia";

          volumes =
            (lib.mapAttrsToList (
              name: mount: "${config.age.secrets.${name}.path}:/run/secrets/${mount}"
            ) secretMounts)
            ++ [
              "${volumes.authelia-config.ref}:/config"
            ];

          environments = lib.mapAttrs' (name: envVar: {
            name = envVar;
            value = "/run/secrets/${secretMounts.${name}}";
          }) envMapping;

          publishPorts = [
            "${toString ports.authelia}:9091/tcp"
          ];
        };
      };
    };
}
