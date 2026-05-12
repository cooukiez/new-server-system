/*
  modules/containers/services/opengist.nix

  part of der-home-server
  created 2026-04-20
*/

{
  config,
  pkgs,
  images,
  ports,
  mkEnv,
  ...
}:
let
  createEnv = mkEnv {
    path = "containers/opengist/env";
    vars = {
      OG_OPENGIST_HOME = "/opengist";

      # todo: private db password
      OG_DB_URI = "postgres://opengist:opengist@host.containers.internal:${toString ports.postgres}/opengist";
      OG_EXTERNAL_URL = config.myServices.opengist.serviceConfig.href;

      # authelia oidc configuration
      OG_OIDC_PROVIDER_NAME = "authelia";
      OG_OIDC_CLIENT_KEY = "opengist";
      OG_OIDC_SECRET = "@PLACEHOLDER_CLIENT_KEY@";
      OG_OIDC_DISCOVERY_URL = "https://auth.home.lan/.well-known/openid-configuration";

      OG_OIDC_GROUP_CLAIM_NAME = "groups";
      OG_OIDC_ADMIN_GROUP = "admins";
    };

    secrets = {
      "PLACEHOLDER_AUTH_SECRET" = config.age.secrets.papra-auth-secret.path;
    };
  };
in
{
  myServices.opengist = {
    serviceConfig = {
      name = "Opengist";
      description = "Unstructured Code Storage";
      serviceType = "Apps";

      subdomain = "gists";
      port = ports.opengistHttp;

      policy = "bypass";

      icon = "opengist";
    };
  };

  age.secrets =
    let
      mkSecret = name: {
        file = ../../../secrets/containers/opengist/${name}.age;
        path = "${envSecretsPrefix}/containers/opengist/${name}";
      };
    in
    {
      opengist-client-key = mkSecret "e_auth-client";
      opengist-db-pass.file = ../../../secrets/containers/opengist/s_db-pass.age;
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.opengist-data.volumeConfig = {
        type = "bind";
        device = "/opt/opengist/data";
      };

      containers.opengist = {
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
          image = "docker-archive:${pkgs.dockerTools.pullImage images.opengist}";
          name = "opengist";
          user = "0:0";

          addHosts = [
            "auth.home.lan:host-gateway"
          ];

          environments = {
            TZ = "Europe/Berlin";

            UID = "0";
            GID = "0";
          };

          environmentFiles = [
            "env/containers/opengist/env"
          ];

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            "${volumes.opengist-data.ref}:/opengist:U"
          ];

          publishPorts = [
            "${toString ports.opengist}:2222/tcp"
            "${toString ports.opengistHttp}:6157/tcp"
          ];
        };
      };
    };
}
