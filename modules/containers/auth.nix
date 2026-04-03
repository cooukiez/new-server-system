{
  config,
  pkgs,
  ...
}:
let
  settingsFormat = pkgs.formats.yaml { };

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

        # user

        # admin
        {
          domain = "dns.home.lan";
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
    
    storage = {
      postgres = {
        address = "tcp://host.containers.internal:5432";
        database = "authelia";
        username = "admin";
      };
    };

    notifier = {
      filesystem = {
        filename = "/config/emails.txt";
      };
    };
  };
in
{
  home.file."containers/authelia/configuration.yml" = {
    source = settingsFormat.generate "authelia-configuration.yml" autheliaSettings;
  };

  age.secrets = {
    auth-jwt = {
      file = ../../secrets/auth-jwt.age;
    };
    auth-session = {
      file = ../../secrets/auth-session.age;
    };
    auth-storage-pw = {
      file = ../../secrets/postgres-pw.age;
    };
    auth-storage-key = {
      file = ../../secrets/auth-storage-key.age;
    };
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

            "${pkgs.coreutils}/bin/chmod 644 /opt/authelia/config/configuration.yml"
            "${pkgs.coreutils}/bin/chmod 644 /opt/authelia/config/users.yml"
          ];
        };

        containerConfig = {
          image = "docker.io/authelia/authelia:latest";
          name = "authelia";

          volumes = [
            # secrets
            "${config.age.secrets.auth-jwt.path}:/run/secrets/JWT_SECRET"
            "${config.age.secrets.auth-session.path}:/run/secrets/SESSION_SECRET"
            "${config.age.secrets.auth-storage-pw.path}:/run/secrets/STORAGE_PASSWORD"
            "${config.age.secrets.auth-storage-key.path}:/run/secrets/STORAGE_ENCRYPTION_KEY"

            # volumes
            "${volumes.authelia-config.ref}:/config"
          ];

          environments = {
            AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE = "/run/secrets/JWT_SECRET";
            AUTHELIA_SESSION_SECRET_FILE = "/run/secrets/SESSION_SECRET";
            AUTHELIA_STORAGE_POSTGRES_PASSWORD_FILE = "/run/secrets/STORAGE_PASSWORD";
            AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE = "/run/secrets/STORAGE_ENCRYPTION_KEY";
          };

          publishPorts = [
            "9091:9091/tcp"
          ];
        };
      };
    };
}
