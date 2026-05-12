/*
  modules/containers/services/linkwarden.nix

  part of der-home-server
  created 2026-04-19
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
  createLinkwardenMeiliEnv = mkEnv {
    path = "containers/link/meili/env";
    vars = {
      MEILI_MASTER_KEY = "@PLACEHOLDER_MEILI_KEY@";
      MEILI_NO_ANALYTICS = "true";
    };

    secrets = {
      PLACEHOLDER_MEILI_KEY = config.age.secrets.link-meili-key.path;
    };
  };

  createLinkwardenEnv = mkEnv {
    path = "containers/link/link/env";
    vars = {
      DATABASE_URL =
        let
          name = "linkwarden";
          user = "linkwarden";
          pass = "@PLACEHOLDER_DB_PASS@";

          host = "host.containers.internal";
          port = toString ports.postgres;
        in
        "postgresql://${user}:${pass}@${host}:${port}/${name}";

      MEILISEARCH_ENDPOINT = "http://linkwarden-meili:7700";
      MEILISEARCH_MASTER_KEY = "@PLACEHOLDER_MEILI_KEY@";

      NEXT_PUBLIC_AUTHELIA_ENABLED = "true";
      AUTHELIA_WELLKNOWN_URL = "https://auth.home.lan/.well-known/openid-configuration";
      AUTHELIA_CLIENT_ID = "linkwarden";
      AUTHELIA_CLIENT_SECRET = "@PLACEHOLDER_CLIENT_KEY@";

      NODE_EXTRA_CA_CERTS = "/certs/ca.crt";

      NEXTAUTH_URL = "https://links.home.lan/api/v1/auth";
      NEXTAUTH_SECRET = "@PLACEHOLDER_NEXT_AUTH@";
      NEXT_PUBLIC_CREDENTIALS_ENABLED = "false";
      NEXT_PUBLIC_DISABLE_REGISTRATION = "true";
    };

    secrets = {
      PLACEHOLDER_CLIENT_KEY = config.age.secrets.link-client-key.path;

      # PLACEHOLDER_DB_PASS = config.age.secrets.link-db-pass.path;
      PLACEHOLDER_DB_PASS = pkgs.writeText "db-pass" "linkwarden";

      PLACEHOLDER_MEILI_KEY = config.age.secrets.link-meili-key.path;
      PLACEHOLDER_NEXT_AUTH = config.age.secrets.link-next-auth.path;
    };
  };
in
{
  myServices.linkwarden = {
    serviceConfig = {
      name = "Linkwarden";
      description = "Bookmark Management System";
      serviceType = "Apps";

      subdomain = "links";
      port = ports.linkwarden;

      policy = "bypass";

      icon = "linkwarden";
    };
  };

  age.secrets =
    let
      mkSecret = name: {
        file = ../../../secrets/containers/link/${name}.age;
      };
    in
    {
      link-client-key = mkSecret "s_auth-client";
      link-db-pass = mkSecret "s_db-pass";
      link-meili-key = mkSecret "s_meili-key";
      link-next-auth = mkSecret "s_next-auth";
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      networks.linkwarden-net = {
        networkConfig = {
          internal = false;
        };
      };

      volumes.linkwarden-meili.volumeConfig = {
        type = "bind";
        device = "/opt/linkwarden/meili";
      };

      volumes.linkwarden-data.volumeConfig = {
        type = "bind";
        device = "/opt/linkwarden/data";
      };

      containers.linkwarden-meili = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";

          ExecStartPre = [
            "+${pkgs.writeShellScript "pre-linkwarden-meili" ''
              ${createLinkwardenMeiliEnv}
            ''}"
          ];
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.meili}";
          name = "linkwarden-meili";
          networks = [ "linkwarden-net" ];

          environmentFiles = [
            "env/containers/link/meili/env"
          ];

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            "${volumes.linkwarden-meili.ref}:/meili_data"
          ];
        };
      };

      containers.linkwarden = {
        autoStart = true;

        unitConfig = {
          Requires = [
            "postgres.service"
            "linkwarden-meili.service"
          ];

          After = [
            "postgres.service"
            "linkwarden-meili.service"
          ];
        };

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";

          ExecStartPre = [
            "+${pkgs.writeShellScript "pre-linkwarden" ''
              ${createLinkwardenEnv}
            ''}"
          ];
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.linkwarden}";
          name = "linkwarden";
          networks = [ "linkwarden-net" ];

          addHosts = [
            "auth.home.lan:host-gateway"
          ];

          environmentFiles = [
            "env/containers/link/link/env"
          ];

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            "${volumes.linkwarden-data.ref}:/data/data"
          ];

          publishPorts = [
            "${toString ports.linkwarden}:3000/tcp"
          ];
        };
      };
    };
}
