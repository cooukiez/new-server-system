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
  envSecretsSuffix,
  envSecretsPrefix,
  ...
}:
let
  papraAuthSettings = {
    providerId = "authelia";
    providerName = "Authelia";
    providerIconUrl = "https://www.authelia.com/images/branding/logo-cropped.png";

    clientId = "papra";
    clientSecret = "PLACEHOLDER_CLIENT_SECRET";

    type = "oidc";
    discoveryUrl = "https://auth.home.lan/.well-known/openid-configuration";
    scopes = [
      "openid"
      "profile"
      "email"
    ];
  };

  papraAuthJson = builtins.toJSON [ papraAuthSettings ];

  papraAuthUnpatchedPath = "${envSecretsSuffix}/papra/auth-client-config";
  papraAuthPatchedPath = "${envSecretsSuffix}/papra/auth-client-config-patched";
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

  home.file."${papraAuthUnpatchedPath}" = {
    text = ''
      AUTH_PROVIDERS_CUSTOMS=${papraAuthJson}
    '';
  };

  age.secrets =
    let
      mkSecret = name: {
        file = ../../../../secrets/${name}.age;
        path = "${envSecretsPrefix}/${name}";
      };
    in
    {
      papra-auth-secret = mkSecret "papra/e_auth-secret";
      papra-storage-key = mkSecret "papra/e_storage-key";
      papra-webhook-secret = mkSecret "papra/e_webhook-secret";

      papra-client-secret.file = ../../../../secrets/auth/clients/s_papra.age;
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
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

          ExecStartPre = [
            "+${pkgs.writeShellScript "pre-papra" ''
              ${pkgs.coreutils}/bin/mkdir -p "/opt/papra/data"

              SECRET_VAL=$(${pkgs.coreutils}/bin/cat ${config.age.secrets.papra-client-secret.path})

              ${pkgs.gnused}/bin/sed "s|PLACEHOLDER_CLIENT_SECRET|$SECRET_VAL|g" \
                ${papraAuthUnpatchedPath} > ${papraAuthPatchedPath}

              ${pkgs.coreutils}/bin/chmod 644 ${papraAuthPatchedPath}
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
            INTAKE_EMAILS_WEBHOOK_SECRET = "JmNtFvWILKGALzaSTcebXtwFmOgbXiYO";
          };

          environmentFiles = [
            "secrets/papra/e_auth-secret"
            "secrets/papra/e_webhook-secret"

            "secrets/papra/auth-client-config-patched"
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
