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
  age.secrets =
    let
      mkSecret = name: {
        file = ../../../secrets/${name}.age;
        path = "${envSecretsPrefix}/${name}";
        mode = "444";
      };
    in
    {
      link-client-key = mkSecret "auth/clients/e_link";
      link-meili-key = mkSecret "link/e_link-meili-key";
      link-input-meili = mkSecret "link/e_meili-key";
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes;
    in
    {
      networks.linkwarden-net = {
        networkConfig = {
          internal = false;
        };
      };

      volumes.linkwarden-data.volumeConfig = {
        type = "bind";
        device = "/opt/linkwarden/data";
      };

      volumes.linkwarden-meili.volumeConfig = {
        type = "bind";
        device = "/opt/linkwarden/meili";
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
          Requires = [ "postgres.service" "linkwarden-meili.service" ];
          After = [ "postgres.service" "linkwarden-meili.service" ];
        };

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "ghcr.io/linkwarden/linkwarden:${linkwardenVersion}";
          name = "linkwarden";
          networks = [ "linkwarden-net" ];

          environments = {
            DATABASE_URL = "postgresql://linkwarden:linkwarden@host.containers.internal:${toString ports.postgres}/linkwarden";
            
            MEILISEARCH_ENDPOINT = "http://linkwarden-meili:7700";
            # MEILISEARCH_MASTER_KEY = "your-meili-master-key";

            NEXT_PUBLIC_AUTHELIA_ENABLED = "true";
            AUTHELIA_WELLKNOWN_URL = "https://auth.home.lan/.well-known/openid-configuration";
            AUTHELIA_CLIENT_ID = "linkwarden";
            # AUTHELIA_CLIENT_SECRET=insecure_secret
          };

          environmentFiles = [
            "secrets/auth/clients/e_link"
            "secrets/link/e_link-meili-key"
          ];

          volumes = [
            "${volumes.linkwarden-data.ref}:/data/data"
          ];

          publishPorts = [
            "${toString ports.linkwarden}:3000/tcp"
          ];
        };
      };
    };
}