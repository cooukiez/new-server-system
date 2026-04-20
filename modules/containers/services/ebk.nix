/*
  modules/containers/services/ebk.nix

  part of der-home-server
  created 2026-04-19
*/

{
  config,
  pkgs,
  ports,
  envSecretsPrefix,
  ...
}:
let
  ebkVersion = "latest";
  ebkSettings = (import ./ebk-config.nix).ebkSettings;
in
{
  myServices.ebk = {
    serviceConfig = {
      name = "ezBookkeeping";
      description = "Personal Finance Management";
      serviceType = "Apps";

      subdomain = "finance";
      port = ports.ebk;

      policy = "bypass";

      icon = "ezbookkeeping";
    };

    containerConfig = {
      files."ezbookkeeping.ini" = {
        source = (pkgs.formats.ini { }).generate "ezbookkeeping.ini" ebkSettings;
      };

      volumes = {
        ebk-data = "/opt/ebk/data";
        ebk-log = "/opt/ebk/log";
      };
    };
  };

  age.secrets =
    let
      mkSecret = name: {
        file = ../../../secrets/${name}.age;
        mode = "444";
      };
    in
    {
      ebk-client-key = mkSecret "auth/clients/s_ebk";
      ebk-secret-key = mkSecret "ebk/s_secret-key";
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.ebk-data.volumeConfig = {
        type = "bind";
        device = config.myServices.ebk.containerConfig.volumes.ebk-data;
      };

      volumes.ebk-log.volumeConfig = {
        type = "bind";
        device = config.myServices.ebk.containerConfig.volumes.ebk-log;
      };

      containers.ebk = {
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
          image = "docker.io/mayswind/ezbookkeeping:${ebkVersion}";
          name = "ebk";

          addHosts = [
            "auth.home.lan:host-gateway"
          ];

          environments = {
            TZ = "Europe/Berlin";

            EBKCFP_SECURITY_SECRET_KEY = "/run/secrets/EBK_SECRET_KEY";
            EBKCFP_AUTH_OAUTH2_CLIENT_SECRET = "/run/secrets/EBK_CLIENT_KEY";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            # config
            "${
              config.myServices.ebk.containerConfig.files."ezbookkeeping.ini".fullPath
            }:/ezbookkeeping/conf/ezbookkeeping.ini:ro,U"

            # secrets
            "${config.age.secrets.ebk-client-key.path}:/run/secrets/EBK_CLIENT_KEY:ro"
            "${config.age.secrets.ebk-secret-key.path}:/run/secrets/EBK_SECRET_KEY:ro"

            # volumes
            "${volumes.ebk-data.ref}:/ezbookkeeping/storage:U"
            "${volumes.ebk-log.ref}:/ezbookkeeping/log:U"
          ];

          publishPorts = [
            "${toString ports.ebk}:8080/tcp"
          ];
        };
      };
    };
}
