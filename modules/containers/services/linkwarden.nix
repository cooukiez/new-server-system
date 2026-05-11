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
  envSecretsPrefix,
  ...
}:
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
        path = "${envSecretsPrefix}/containers/link/${name}";
        mode = "444";
      };
    in
    {
      link-client-key = mkSecret "e_auth-client";
      link-meili-key = mkSecret "e_link-meili-key";
      link-input-meili = mkSecret "e_meili-key";
      link-next-auth = mkSecret "e_next-auth";

      link-db-pass.file = ../../../secrets/containers/link/s_db-pass.age;
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
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.meili}";
          name = "linkwarden-meili";
          networks = [ "linkwarden-net" ];

          environments = {
            MEILI_NO_ANALYTICS = "true";
          };

          environmentFiles = [
            "secrets/containers/link/e_meili-key"
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
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.linkwarden}";
          name = "linkwarden";
          networks = [ "linkwarden-net" ];

          addHosts = [
            "auth.home.lan:host-gateway"
          ];

          environments = {
            # todo: private db password
            DATABASE_URL = "postgresql://linkwarden:linkwarden@host.containers.internal:${toString ports.postgres}/linkwarden";

            MEILISEARCH_ENDPOINT = "http://linkwarden-meili:7700";

            NEXT_PUBLIC_AUTHELIA_ENABLED = "true";
            AUTHELIA_WELLKNOWN_URL = "https://auth.home.lan/.well-known/openid-configuration";
            AUTHELIA_CLIENT_ID = "linkwarden";

            NODE_EXTRA_CA_CERTS = "/certs/ca.crt";

            NEXTAUTH_URL = "https://links.home.lan/api/v1/auth";
            NEXT_PUBLIC_CREDENTIALS_ENABLED = "false";
            NEXT_PUBLIC_DISABLE_REGISTRATION = "true";
          };

          environmentFiles = [
            "secrets/containers/link/e_auth-client"
            "secrets/containers/link/e_link-meili-key"
            "secrets/containers/link/e_next-auth"
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
