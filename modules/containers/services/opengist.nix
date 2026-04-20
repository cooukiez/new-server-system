/*
  modules/containers/services/vnstat.nix

  part of der-home-server
  created 2026-04-16
*/

{
  config,
  ports,
  ...
}:
let
  meiliVersion = "latest";
  opengistVersion = "1";

  meiliAPIKey = "b1c6c319229877b98faeab53957defae85193cee1b72c5fa96cacb5fe2fee734";

  opengistSettings = {
    db-uri = "postgres://opengist:opengist@host.containers.internal:${toString ports.postgres}/opengist";

    index.meili.host = "http://opengist-meili:7700";
    index.meili.api-key = meiliAPIKey;

    oidc = {
      provider-name = "authelia";
      client-key = "opengist";
      discovery-url = "https://auth.home.lan.com/.well-known/openid-configuration";

      group-claim-name = "groups";
      admin-group = "admins";
    };

    "external-url" = "https://opengist.example.com";
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

    containerConfig = {
      files."config.yml" = {
        source = (pkgs.formats.yaml { }).generate "config.yml" radicaleSettings;
      };

      volumes = {
        opengist-meili = "/opt/opengist/meili";
        opengist-data = "/opt/opengist/data";
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
      opengist-client-key = mkSecret "auth/clients/e_opengist";
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      networks.opengist-net = {
        networkConfig = {
          internal = false;
        };
      };

      volumes.opengist-meili.volumeConfig = {
        type = "bind";
        device = config.myServices.opengist.containerConfig.volumes.opengist-meili;
      };

      volumes.opengist-data.volumeConfig = {
        type = "bind";
        device = config.myServices.opengist.containerConfig.volumes.opengist-data;
      };

      containers.opengist-meili = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/getmeili/meilisearch:${meiliVersion}";
          name = "opengist-meili";
          networks = [ "opengist-net" ];

          environments = {
            MEILI_NO_ANALYTICS = "true";
            MEILI_MASTER_KEY = meiliAPIKey;
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            "${volumes.opengist-meili.ref}:/meili_data"
          ];
        };
      };

      containers.opengist = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "ghcr.io/thomiceli/opengist:${opengistVersion}";
          name = "opengist";
          networks = [ "opengist-net" ];

          environments = {
            TZ = "Europe/Berlin";
          };

          environmentFiles = [
            "secrets/auth/clients/e_opengist"
          ];

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            "${config.myServices.opengist.containerConfig.files."config.yml".fullPath}:/config.yml:ro"

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
