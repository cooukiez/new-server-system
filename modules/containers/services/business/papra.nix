/*
  modules/containers/services/papra.nix

  part of der-home-server
  created 2026-04-16
*/

{
  config,
  pkgs,
  images,
  ports,
  envSecretsPrefix,
  mkEnv,
  mkSecretEnv,
  documentsPath,
  ...
}:
let
  createEnv = mkEnv {
    path = "containers/papra/env";
    vars = {
      TZ = "Europa/Berlin";

      APP_BASE_URL = "https://papra.home.lan";

      PORT = "1221";
      SERVER_HOSTNAME = "0.0.0.0";

      DOCUMENT_STORAGE_FILESYSTEM_ROOT = "/data";
      DOCUMENTS_CONTENT_EXTRACTION_ENABLED = "true";
      DOCUMENTS_OCR_LANGUAGES = "deu,eng";

      NODE_EXTRA_CA_CERTS = "/certs/ca.crt";

      AUTH_FIRST_USER_AS_ADMIN = "true";
      AUTH_PROVIDERS_EMAIL_IS_ENABLED = "false";

      INTAKE_EMAILS_IS_ENABLED = "true";
      INTAKE_EMAILS_DRIVER = "catch-all";

      # todo: make this private and update in node-red
      INTAKE_EMAILS_WEBHOOK_SECRET = "JmNtFvWILKGALzaSTcebXtwFmOgbXiYO";

      # authelia oidc configuration
      AUTH_PROVIDERS_CUSTOMS = "${builtins.toJSON [
        {
          providerId = "authelia";
          providerName = "Authelia";
          providerIconUrl = "https://www.authelia.com/images/branding/logo-cropped.png";

          clientId = "papra";
          clientSecret = "@PLACEHOLDER_CLIENT_SECRET@";

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
      "PLACEHOLDER_CLIENT_SECRET" = config.age.secrets.papra-client-key.path;
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
        path = "${envSecretsPrefix}/containers/papra/${name}";
      };
    in
    {
      papra-auth-secret = mkSecret "e_auth-secret";
      papra-webhook-secret = mkSecret "e_webhook-secret";

      papra-client-key = mkSecret "s_auth-client";
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

          environmentFiles = [
            "secrets/containers/papra/e_auth-secret"
            "secrets/containers/papra/e_webhook-secret"

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
