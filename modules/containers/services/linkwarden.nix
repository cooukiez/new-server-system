/*
  modules/containers/services/linkwarden.nix

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
  meiliVersion = "latest";
  linkwardenVersion = "latest";
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

    containerConfig = {
      volumes = {
        linkwarden-meili = "/opt/linkwarden/meili";
        linkwarden-data = "/opt/linkwarden/data";
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
      link-meili-key = mkSecret "link/e_link-meili-key";

      link-client-key = mkSecret "auth/clients/e_link";
      link-input-meili = mkSecret "link/e_meili-key";
      link-next-auth = mkSecret "link/e_next-auth";
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
        device = config.myServices.linkwarden.containerConfig.volumes.linkwarden-meili;
      };

      volumes.linkwarden-data.volumeConfig = {
        type = "bind";
        device = config.myServices.linkwarden.containerConfig.volumes.linkwarden-data;
      };

      containers.linkwarden-meili = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/getmeili/meilisearch:${meiliVersion}";
          name = "linkwarden-meili";
          networks = [ "linkwarden-net" ];

          environments = {
            MEILI_NO_ANALYTICS = "true";
          };

          environmentFiles = [
            "secrets/link/e_meili-key"
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
          image = "ghcr.io/linkwarden/linkwarden:${linkwardenVersion}";
          name = "linkwarden";
          networks = [ "linkwarden-net" ];

          addHosts = [
            "auth.home.lan:host-gateway"
          ];

          environments = {
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
            "secrets/auth/clients/e_link"
            "secrets/link/e_link-meili-key"
            "secrets/link/e_next-auth"
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
