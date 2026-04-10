/*
  modules/containers/auth.nix

  part of der-home-server
  created 2026-04-10
*/

{
  config,
  pkgs,
  ports,
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
      rules = [
        {
          domain = "auth.home.lan";
          policy = "bypass";
        }
        {
          domain = "home.lan";
          policy = "bypass";
        }

        {
          domain = "monitor.home.lan";
          policy = "bypass";
        }
        {
          domain = "immich.home.lan";
          policy = "bypass";
        }

        # admin (without login prompt)
        {
          domain = "dns.home.lan";
          policy = "one_factor";
          subject = [ "group:admins" ];
        }
        {
          domain = "glances.home.lan";
          policy = "one_factor";
          subject = [ "group:admins" ];
        }
        {
          domain = "prometheus.home.lan";
          policy = "one_factor";
          subject = [ "group:admins" ];
        }
      ];
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

        clients = [
          {
            client_id = "immich";
            client_name = "Immich";
            client_secret = "$pbkdf2-sha512$310000$X5CgmGSCM2XEmtT0jqohVA$H8TqZ1CSfnrr8M.zzjO7VAuNQtaZf2saqVBwCrTzNeHlVpaAhuQV8nhNUJ8p8jktsvT7oJBdsHa7ftQfbGynVQ";

            public = false;
            authorization_policy = "two_factor";
            require_pkce = false;

            redirect_uris = [
              "https://immich.home.lan/auth/login"
              "https://immich.home.lan/user-settings"
              "app.immich:///oauth-callback"
            ];

            scopes = [
              "openid"
              "profile"
              "email"
            ];

            response_types = [ "code" ];
            grant_types = [ "authorization_code" ];

            access_token_signed_response_alg = "none";
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "client_secret_post";
          }
          {
            client_id = "grafana";
            client_name = "Grafana";
            client_secret = "$pbkdf2-sha512$310000$j//xOaGDVHfltGPTrdpXAg$cjNHWiElFa8S2PlanW1.5BzjgBYsev2POF.LPdPzYGgabkC.HNEUZbP4Rs2GfpONTmIS/WcVgjDpZAlIW5FtdQ";

            claims_policy = "grafana";

            public = false;
            authorization_policy = "two_factor";
            require_pkce = true;
            pkce_challenge_method = "S256";

            redirect_uris = [
              "https://monitor.home.lan/login/generic_oauth"
            ];

            scopes = [
              "openid"
              "profile"
              "groups"
              "email"
            ];

            response_types = [ "code" ];
            grant_types = [ "authorization_code" ];

            access_token_signed_response_alg = "RS256";
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "client_secret_basic";
          }
        ];
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
in
{
  home.file."containers/authelia/configuration.yml" = {
    source = settingsFormat.generate "configuration.yml" autheliaSettings;
  };

  age.secrets = builtins.mapAttrs (_: f: { file = ../../secrets/${f}.age; }) {
    auth-jwt = "auth-jwt";
    auth-session = "auth-session";

    auth-storage-pw = "postgres-pw";
    auth-storage-key = "auth-storage-key";

    auth-oidc-hmac = "auth-oidc-hmac";
    auth-oidc-key = "auth-oidc-key";

    smtp-pw = "smtp-pw";
  };

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

            "${pkgs.yq-go}/bin/yq -i '.identity_providers.oidc.jwks[0].key = load_str(\"${config.age.secrets.auth-oidc-key.path}\")' /opt/authelia/config/configuration.yml"

            "${pkgs.coreutils}/bin/chmod 644 /opt/authelia/config/configuration.yml"
            "${pkgs.coreutils}/bin/chmod 644 /opt/authelia/config/users.yml"
          ];
        };

        containerConfig = {
          image = "docker.io/authelia/authelia:${autheliaVersion}";
          name = "authelia";

          volumes = [
            # secrets
            "${config.age.secrets.auth-jwt.path}:/run/secrets/JWT_SECRET"
            "${config.age.secrets.auth-session.path}:/run/secrets/SESSION_SECRET"

            "${config.age.secrets.auth-storage-pw.path}:/run/secrets/STORAGE_PASSWORD"
            "${config.age.secrets.auth-storage-key.path}:/run/secrets/STORAGE_ENCRYPTION_KEY"

            "${config.age.secrets.auth-oidc-hmac.path}:/run/secrets/OIDC_HMAC_SECRET"
            "${config.age.secrets.auth-oidc-key.path}:/run/secrets/OIDC_RSA_KEY"

            "${config.age.secrets.smtp-pw.path}:/run/secrets/SMTP-PW"

            # volumes
            "${volumes.authelia-config.ref}:/config"
          ];

          environments = {
            AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE = "/run/secrets/JWT_SECRET";
            AUTHELIA_SESSION_SECRET_FILE = "/run/secrets/SESSION_SECRET";

            AUTHELIA_STORAGE_POSTGRES_PASSWORD_FILE = "/run/secrets/STORAGE_PASSWORD";
            AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE = "/run/secrets/STORAGE_ENCRYPTION_KEY";

            AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET_FILE = "/run/secrets/OIDC_HMAC_SECRET";

            AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = "/run/secrets/SMTP-PW";
          };

          publishPorts = [
            "${toString ports.authelia}:9091/tcp"
          ];
        };
      };
    };
}
