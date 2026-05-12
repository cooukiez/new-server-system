/*
  modules/containers/services/trek.nix

  part of server system
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
    path = "containers/trek/env";
    vars = {
      NODE_ENV = "production";
      PORT = "3000";
      APP_URL = config.myServices.trek.serviceConfig.href;

      NODE_EXTRA_CA_CERTS = "/certs/ca.crt";

      # temporary for first run
      ADMIN_EMAIL = "trek@local";

      # authelia oidc configuration
      OIDC_ISSUER = "https://auth.home.lan";
      OIDC_CLIENT_ID = "trek";
      OIDC_CLIENT_SECRET = "@PLACEHOLDER_CLIENT_KEY@";

      OIDC_DISPLAY_NAME = "Authelia";
      OIDC_ONLY = "true";

      OIDC_ADMIN_CLAIM = "groups";
      OIDC_ADMIN_VALUE = "admins";

      OIDC_SCOPE = "openid email profile groups";
      OIDC_DISCOVERY_URL = "https://auth.home.lan/.well-known/openid-configuration";
    };

    secrets = {
      PLACEHOLDER_CLIENT_KEY = config.age.secrets.trek-client-key.path;
    };
  };
in
{
  myServices.trek = {
    serviceConfig = {
      name = "TREK";
      description = "Travel Tracking and Planning";
      serviceType = "Apps";

      subdomain = "trek";
      port = ports.trek;

      policy = "bypass";
      icon = "https://raw.githubusercontent.com/mauriceboe/TREK/6df5edfbdb387d4dfb9c9260c0f99569a71dcd8a/server/public/icons/icon.svg";
    };
  };

  age.secrets =
    let
      mkSecret = name: {
        file = ../../../secrets/containers/trek/${name}.age;
      };
    in
    {
      trek-client-key = mkSecret "s_auth-client";
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.trek-data.volumeConfig = {
        type = "bind";
        device = "/opt/trek/data";
      };

      volumes.trek-uploads.volumeConfig = {
        type = "bind";
        device = "/opt/trek/uploads";
      };

      containers.trek = {
        autoStart = true;

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";

          ExecStartPre = [
            "+${pkgs.writeShellScript "pre-trek" ''
              ${createEnv}
            ''}"
          ];
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.trek}";
          name = "trek";

          addHosts = [
            "auth.home.lan:host-gateway"
          ];

          environments = {
            TZ = "Europe/Berlin";
          };

          environmentFiles = [
            "env/containers/trek/env"
          ];

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            "${volumes.trek-data.ref}:/app/data:U"
            "${volumes.trek-uploads.ref}:/app/uploads:U"
          ];

          publishPorts = [
            "${toString ports.trek}:3000/tcp"
          ];
        };
      };
    };
}
