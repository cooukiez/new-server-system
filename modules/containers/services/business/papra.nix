/*
  modules/containers/services/business/papra.nix

  part of server system
  created 2026-04-16
*/

{
  config,
  pkgs,
  images,
  ports,
  mkEnv,
  documentsPath,
  ...
}:
let
  createEnv = mkEnv {
    path = "containers/papra/env";
    vars = {
      APP_BASE_URL = "https://papra.home.lan";

      PORT = "1221";
      SERVER_HOSTNAME = "0.0.0.0";

      DOCUMENT_STORAGE_FILESYSTEM_ROOT = "/data";
      DOCUMENTS_CONTENT_EXTRACTION_ENABLED = "true";
      DOCUMENTS_OCR_LANGUAGES = "deu,eng";

      NODE_EXTRA_CA_CERTS = "/certs/ca.crt";

      AUTH_SECRET = "@PLACEHOLDER_AUTH_SECRET@";
      AUTH_FIRST_USER_AS_ADMIN = "true";
      AUTH_PROVIDERS_EMAIL_IS_ENABLED = "false";

      INTAKE_EMAILS_IS_ENABLED = "true";
      INTAKE_EMAILS_DRIVER = "catch-all";

      INTAKE_EMAILS_WEBHOOK_SECRET = "@PLACEHOLDER_WEBHOOK_SECRET@";

      AUTH_PROVIDERS_CUSTOMS = "${builtins.toJSON [
        {
          providerId = "authelia";
          providerName = "Authelia";
          providerIconUrl = "https://www.authelia.com/images/branding/logo-cropped.png";

          clientId = "papra";
          clientSecret = "@PLACEHOLDER_CLIENT_KEY@";

          type = "oidc";
          discoveryUrl = "https://auth.home.lan/.well-known/openid-configuration";
          scopes = [
            "openid"
            "profile"
            "email"
          ];
        }
      ]}";
    };

    secrets = {
      "PLACEHOLDER_AUTH_SECRET" = config.age.secrets.papra-auth-secret.path;
      "PLACEHOLDER_CLIENT_KEY" = config.age.secrets.papra-client-key.path;
      "PLACEHOLDER_WEBHOOK_SECRET" = config.age.secrets.papra-webhook-secret.path;
    };
  };
in
{
  myServices.papra = {
    serviceConfig = {
      name = "Papra";
      description = "Document Management System";
      serviceType = "Apps";

      subdomain = "papra";
      port = ports.papra;

      policy = "bypass";

      icon = "papra";
    };
  };

  age.secrets =
    let
      mkSecret = name: {
        file = ../../../../secrets/containers/papra/${name}.age;
      };
    in
    {
      papra-auth-secret = mkSecret "s_auth-secret";
      papra-client-key = mkSecret "s_auth-client";
      papra-storage-key = mkSecret "s_storage-key";
      papra-webhook-secret = mkSecret "s_webhook-secret";
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.data-documents.volumeConfig = {
        type = "bind";
        device = documentsPath;
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

          ExecStartPre = [
            "+${pkgs.writeShellScript "pre-papra" ''
              ${createEnv}
            ''}"
          ];
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.papra}";
          name = "papra";

          addHosts = [
            "auth.home.lan:host-gateway"
          ];

          environments = {
            TZ = "Europe/Berlin";
          };

          environmentFiles = [
            "env/containers/papra/env"
          ];

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            # volumes
            "${volumes.data-documents.ref}:/data:U"
            "${volumes.papra-data.ref}:/app/app-data:U"
          ];

          publishPorts = [
            "${toString ports.papra}:1221/tcp"
          ];
        };
      };
    };
}
