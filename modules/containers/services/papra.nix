/*
  modules/containers/services/papra.nix

  part of der-home-server
  created 2026-04-14
*/

{
  config,
  ports,
  envSecretsPrefix,
  ...
}:
let
  papraVersion = "latest-rootless";
in
{
  age.secrets =
    let
      mkSecret = name: {
        file = ../../../secrets/${name}.age;
        path = "${envSecretsPrefix}/${name}";
      };
    in
    {
      papra-storage-key = mkSecret "papra/storage-key";
      papra-auth-secret = mkSecret "papra/auth-secret";

      # see config at bottom
      papra-auth-client = mkSecret "papra/auth-client";
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes;
    in
    {
      volumes.data-documents.volumeConfig = {
        type = "bind";
        device = "/data/documents";
      };

      volumes.papra-data.volumeConfig = {
        type = "bind";
        device = "/opt/papra/data";
      };

      containers.papra = {
        autoStart = true;

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "ghcr.io/papra-hq/papra:${papraVersion}";
          name = "papra";
          user = "0:0"; # run as root

          addHosts = [
            "auth.home.lan:host-gateway"
          ];

          # exec = "/bin/sh -c 'update-ca-certificates && pnpm start:with-migrations'";

          environments = {
            TZ = "Europa/Berlin";

            APP_BASE_URL = "https://papra.home.lan";

            PORT = "1221";
            SERVER_HOSTNAME = "0.0.0.0";

            # DATABASE_URL = "postgres://papra:papra@host.containers.internal:5432/papra";

            DOCUMENT_STORAGE_FILESYSTEM_ROOT = "/data";
            DOCUMENTS_CONTENT_EXTRACTION_ENABLED = "true";
            DOCUMENTS_OCR_LANGUAGES = "deu,eng";

            NODE_EXTRA_CA_CERTS = "/certs/home.lan.crt";

            AUTH_FIRST_USER_AS_ADMIN = "true";
            AUTH_PROVIDERS_EMAIL_IS_ENABLED = "false";

            INTAKE_EMAILS_IS_ENABLED = "true";
            INTAKE_EMAILS_DRIVER = "catch-all";
            INTAKE_EMAILS_WEBHOOK_SECRET = "JmNtFvWILKGALzaSTcebXtwFmOgbXiYO";
          };

          environmentFiles = [
            "secrets/papra/storage-key"
            "secrets/papra/auth-secret"

            "secrets/papra/auth-client"
          ];

          volumes = [
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/certs/home.lan.crt:/usr/local/share/ca-certificates/home.lan.crt:ro"
            "/certs/home.lan.crt:/certs/home.lan.crt:ro"

            # volumes
            "${volumes.data-documents.ref}:/data"
            "${volumes.papra-data.ref}:/app/app-data"
          ];

          publishPorts = [
            "${toString ports.papra}:1221/tcp"
          ];
        };
      };
    };
}

# echo -n 'AUTH_PROVIDERS_CUSTOMS=[{"providerId":"authelia","providerName":"Authelia","providerIconUrl":"https://www.authelia.com/images/branding/logo-cropped.png","clientId":"papra","clientSecret":"","type":"oidc","discoveryUrl":"https://auth.home.lan/.well-known/openid-configuration","scopes":["openid","profile","email"]}]' | agenix -e papra/auth-client.age
