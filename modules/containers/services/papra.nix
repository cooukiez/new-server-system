/*
  modules/containers/services/papra.nix

  part of der-home-server
  created 2026-04-14
*/

{
  config,
  pkgs,
  ports,
  envSecretsSuffix,
  envSecretsPrefix,
  ...
}:
let
  papraVersion = "latest-rootless";

  papraAuthSettings = (import ../auth/oidc-client-configs.nix).papra;

  papraAuthJson = builtins.toJSON [ papraAuthSettings ];

  papraAuthUnpatchedPath = "${envSecretsSuffix}/papra/auth-client-config";
  papraAuthPatchedPath = "${envSecretsSuffix}/papra/auth-client-config-patched";

  patchCommand = "${pkgs.gnused}/bin/sed -i \"s|PLACEHOLDER_CLIENT_SECRET|$(cat ${config.age.secrets.papra-client-secret.path})|g\"";
in
{
  home.file."${papraAuthUnpatchedPath}" = {
    text = ''
      AUTH_PROVIDERS_CUSTOMS=${papraAuthJson}
    '';
  };

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

      papra-client-secret.file = ../../../secrets/papra/client-secret.age;
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

          ExecStartPre = [
            "-${pkgs.coreutils}/bin/rm -f ${papraAuthPatchedPath}"

            (pkgs.writeShellScript "patch-papra-auth" ''
              SECRET_VAL=$(${pkgs.coreutils}/bin/cat ${config.age.secrets.papra-client-secret.path})

              ${pkgs.gnused}/bin/sed "s|PLACEHOLDER_CLIENT_SECRET|$SECRET_VAL|g" \
                ${papraAuthUnpatchedPath} > ${papraAuthPatchedPath}
              ${pkgs.coreutils}/bin/chmod 644 ${papraAuthPatchedPath}
            '')
          ];
        };

        containerConfig = {
          image = "ghcr.io/papra-hq/papra:${papraVersion}";
          name = "papra";
          user = "0:0"; # run as root

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

            "secrets/papra/auth-client-config-patched"
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