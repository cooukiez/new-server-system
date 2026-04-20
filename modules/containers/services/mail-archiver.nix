/*
  modules/containers/services/mail-archiver.nix

  part of der-home-server
  created 2026-04-19
*/

{
  config,
  ports,
  envSecretsPrefix,
  ...
}:
let
  mailArchiverVersion = "latest";
in
{
  myServices.mail-archiver = {
    serviceConfig = {
      name = "Mail-Archiver";
      description = "Mail Archiving System";
      serviceType = "Apps";

      subdomain = "mail";
      port = ports.mail-archiver;

      policy = "bypass";

      icon = "mail-archiver";
    };

    containerConfig = {
      volumes = {
        mail-archiver-protection-keys = "/opt/mail-archiver/protection-keys";
      };
    };
  };

  age.secrets =
    let
      mkSecret = name: {
        file = ../../../secrets/${name}.age;
        path = "${envSecretsPrefix}/${name}";
        mode = "444";
      };
    in
    {
      archiver-admin-pass = mkSecret "archiver/e_admin-pass";
      archiver-admin-pass = mkSecret "auth//e_client-key";
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.mail-archiver-protection-keys.volumeConfig = {
        type = "bind";
        device = config.myServices.mail-archiver.containerConfig.volumes.mail-archiver-protection-keys;
      };

      containers.mail-archiver = {
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
          image = "docker.io/s1t5/mailarchiver:${mailArchiverVersion}";
          name = "mail-archiver";

          addHosts = [
            "auth.home.lan:host-gateway"
          ];

          environments = {
            TZ = "Europe/Berlin";
            TimeZone__DisplayTimeZoneId = "Europe/Berlin";

            ConnectionStrings__DefaultConnection = "Host=host.containers.internal;Port=5432;Database=mail-archiver;Username=archiver;Password=archiver";

            Authentication__Username = "admin";
            Authentication__SessionTimeoutMinutes = "60";

            BandwidthTracking__Enabled = "false";
            BandwidthTracking__DailyLimitMb = "25000";

            AllowedHosts = config.myServices.mail-archiver.serviceConfig.domain;

            DatabaseMaintenance__Enabled = "true";
            DatabaseMaintenance__DailyExecutionTime = "01:00";
            DatabaseMaintenance__TimeoutMinutes = "30";

            View__DefaultToPlainText = "true";
            View__BlockExternalResources = "false";

            # authelia oidc configuration
            OAuth__Enabled = "true";
            OAuth__Authority = "https://auth.home.lan";
            OAuth__ClientId = "mail-archiver";        
            
            # scopes defined as indexed keys
            OAuth__ClientScopes__0 = "openid";
            OAuth__ClientScopes__1 = "profile";
            OAuth__ClientScopes__2 = "email";
            OAuth__ClientScopes__3 = "groups";

            OAuth__DisablePasswordLogin = "false";
            
          };

          environmentFiles = [
            "secrets/archiver/e_admin-pass"
            "secrets/archiver/e_client-key"
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
            "${toString ports.mail-archiver}:5000/tcp"
          ];
        };
      };
    };
}
