/*
modules/containers/services/business/mail-archiver.nix

part of server system
created 2026-05-13 by ludw
*/
{
  config,
  pkgs,
  images,
  ports,
  mkEnv,
  ...
}: let
  createEnv = mkEnv {
    path = "containers/archiver/env";
    vars = {
      TimeZone__DisplayTimeZoneId = "Europe/Berlin";

      Authentication__Username = "admin";
      Authentication__Password = "@PLACEHOLDER_ADMIN_PASS@";
      Authentication__SessionTimeoutMinutes = "60";

      BandwidthTracking__Enabled = "false";
      BandwidthTracking__DailyLimitMb = "25000";

      AllowedHosts = config.myServices.mailArchiver.serviceConfig.domain;

      DatabaseMaintenance__Enabled = "true";
      DatabaseMaintenance__DailyExecutionTime = "01:00";
      DatabaseMaintenance__TimeoutMinutes = "30";

      ConnectionStrings__DefaultConnection = builtins.concatStringsSep ";" [
        "Host=mail-archiver-postgres"
        "Port=5432"
        "Database=mail-archiver"

        "Username=admin"
        "Password=@PLACEHOLDER_DB_PASS@"
      ];

      View__DefaultToPlainText = "true";
      View__BlockExternalResources = "false";

      # authelia oidc configuration
      OAuth__Enabled = "true";
      OAuth__Authority = "https://auth.home.lan";
      OAuth__ClientId = "mail-archiver";
      OAuth__ClientSecret = "@PLACEHOLDER_CLIENT_KEY@";

      # scopes defined as indexed keys
      OAuth__ClientScopes__0 = "openid";
      OAuth__ClientScopes__1 = "profile";
      OAuth__ClientScopes__2 = "email";
      OAuth__ClientScopes__3 = "groups";

      Kestrel__Limits__MaxRequestHeadersTotalSize = "65536";
      Kestrel__Limits__MaxRequestHeaderFieldSize = "32768";
      Kestrel__Endpoints__Http__Url = "http://0.0.0.0:5000";

      OAuth__DisablePasswordLogin = "true";
      OAuth__AutoApproveUsers = "true";

      # automatic admins
      OAuth__AdminEmails__0 = "management.homeserver@mailbox.org";
      OAuth__AdminEmails__1 = "ludwig.geyer@mailbox.org";
    };

    secrets = {
      PLACEHOLDER_ADMIN_PASS = config.age.secrets.archiver-admin-pass.path;
      PLACEHOLDER_CLIENT_KEY = config.age.secrets.archiver-client-key.path;
      PLACEHOLDER_DB_PASS = config.age.secrets.archiver-db-pass.path;
    };
  };
in {
  myServices.mailArchiver = {
    serviceConfig = {
      name = "Mail-Archiver";
      description = "Mail Archiving System";
      serviceType = "Apps";

      subdomain = "mail";
      port = ports.mailArchiver;

      policy = "bypass";

      icon = "mail-archiver";
    };
  };

  age.secrets = let
    mkSecret = name: {
      file = ../../../../secrets/containers/archiver/${name}.age;
    };
  in {
    archiver-admin-pass = mkSecret "s_admin-pass";
    archiver-client-key = mkSecret "s_auth-client";
    archiver-db-pass = mkSecret "s_db-pass";
  };

  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) volumes networks;
  in {
    networks.mail-archiver-net = {
      networkConfig = {
        internal = false;
      };
    };

    volumes.mail-archiver-db.volumeConfig = {
      type = "bind";
      device = "/opt/mail-archiver/db";
    };

    volumes.mail-archiver-protection-keys.volumeConfig = {
      type = "bind";
      device = "/opt/mail-archiver/protection-keys";
    };

    containers.mail-archiver-postgres = {
      autoStart = true;
      serviceConfig = {
        Restart = "always";
        RestartSec = "10";
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.postgres}";
        name = "mail-archiver-postgres";
        networks = [networks.mail-archiver-net.ref networks.postgres-net.ref];

        environments = {
          POSTGRES_USER = "admin";
          POSTGRES_PASSWORD_FILE = "/run/secrets/ARCHIVER_DB_PASS";

          POSTGRES_DB = "mail-archiver";
        };

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          "${volumes.mail-archiver-db.ref}:/var/lib/postgresql:U"
          "${config.age.secrets.archiver-db-pass.path}:/run/secrets/ARCHIVER_DB_PASS:ro"
        ];

        publishPorts = [
          "${toString ports.mailArchiverDb}:5432/tcp"
        ];
      };
    };

    containers.mail-archiver = {
      autoStart = true;

      unitConfig = {
        Requires = ["mail-archiver-postgres.service"];
        After = ["mail-archiver-postgres.service"];
      };

      serviceConfig = {
        Restart = "always";
        RestartSec = "10";

        ExecStartPre = [
          "+${pkgs.writeShellScript "pre-archiver" ''
            ${createEnv}
          ''}"
        ];
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.mail-archiver}";
        name = "mail-archiver";
        networks = [networks.mail-archiver-net.ref];

        addHosts = [
          "auth.home.lan:host-gateway"
        ];

        environmentFiles = [
          "env/containers/archiver/env"
        ];

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          # certificates
          "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
          "/certs/ca.crt:/certs/ca.crt:ro"

          "${volumes.mail-archiver-protection-keys.ref}:/app/DataProtection-Keys:U"
        ];

        publishPorts = [
          "${toString ports.mailArchiver}:5000/tcp"
        ];
      };
    };
  };
}
