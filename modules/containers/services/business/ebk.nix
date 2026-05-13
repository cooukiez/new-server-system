/*
modules/containers/services/business/ebk.nix

part of server system
created 2026-04-19
*/
{
  config,
  pkgs,
  images,
  ports,
  envSecretsPrefix,
  ...
}: let
  ebkSettings = (import ./ebk-config.nix {inherit config ports;}).ebkSettings;
in {
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
  };

  home.file."containers/ebk/ezbookkeeping.ini".source =
    (pkgs.formats.ini {}).generate "ebk-settings"
    ebkSettings;

  age.secrets = let
    mkSecret = name: {
      file = ../../../../secrets/containers/ebk/${name}.age;
      mode = "444";
    };
  in {
    ebk-client-key = mkSecret "s_auth-client";
    ebk-db-pass = mkSecret "s_db-pass";
    ebk-secret-key = mkSecret "s_secret-key";
  };

  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) volumes networks pods;
  in {
    volumes.ebk-data.volumeConfig = {
      type = "bind";
      device = "/opt/ebk/data";
    };

    volumes.ebk-log.volumeConfig = {
      type = "bind";
      device = "/opt/ebk/log";
    };

    containers.ebk = {
      autoStart = true;

      unitConfig = {
        Requires = ["postgres.service"];
        After = ["postgres.service"];
      };

      serviceConfig = {
        Restart = "always";
        RestartSec = "10";
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.ebk}";
        name = "ebk";

        addHosts = [
          "auth.home.lan:host-gateway"
        ];

        environments = {
          TZ = "Europe/Berlin";

          EBKCFP_AUTH_OAUTH2_CLIENT_SECRET = "/run/secrets/EBK_CLIENT_KEY";
          EBKCFP_DATABASE_PASSWD = "/run/secrets/EBK_DB_PASS";
          EBKCFP_SECURITY_SECRET_KEY = "/run/secrets/EBK_SECRET_KEY";
        };

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          # certificates
          "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
          "/certs/ca.crt:/certs/ca.crt:ro"

          # config
          "${config.home.homeDirectory}/containers/ebk/ezbookkeeping.ini:/ezbookkeeping/conf/ezbookkeeping.ini:ro,U"

          # secrets
          "${config.age.secrets.ebk-client-key.path}:/run/secrets/EBK_CLIENT_KEY:ro"
          "${config.age.secrets.ebk-db-pass.path}:/run/secrets/EBK_DB_PASS:ro"
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
