/*
  modules/containers/services/papra.nix

  part of der-home-server
  created 2026-04-14
*/

{
  config,
  pkgs,
  ports,
  envSecretsPrefix,
  ...
}:
let
  settingsFormat = pkgs.formats.ini { };

  ebkVersion = "latest";

  # ezbookkeeping settings
  ebkSettings = {
    server = {
      domain = "finance.home.lan";
      root_url = "https://finance.home.lan/";
      enable_gzip = true;
    };

    database = {
      type = "postgres";
      host = "host.containers.internal:5432";

      name = "ebk";
      user = "ebk";
      passwd = "ebk";
    };

    auth = {
      enable_oauth2_auth = true;
      oauth2_provider = "oidc";
      oauth2_client_id = "ezbookkeeping";
      oauth2_use_pkce = true;

      oidc_provider_base_url = "https://auth.home.lan";
      enable_oidc_display_name = true;
      oidc_custom_display_name = "Authelia";
    };
  };
in
{
  home.file."containers/ebk/ezbookkeeping.ini" = {
    source = settingsFormat.generate "ezbookkeeping.ini" ebkSettings;
  };

  age.secrets =
    let
      mkSecret = name: {
        file = ../../../secrets/${name}.age;
        path = "${envSecretsPrefix}/${name}";
      };
    in
    {
      ebk-secret-key = mkSecret "ebk/secret-key";
      ebk-client-key = mkSecret "ebk/client-key";
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes;
    in
    {
      volumes.ebk-data.volumeConfig = {
        type = "bind";
        device = "/opt/ebk/data";
      };

      volumes.ebk-log.volumeConfig = {
        type = "bind";
        device = "/opt/ebk/log";
      };

      containers.ebk = {
        autoStart = true;

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/mayswind/ezbookkeeping:${ebkVersion}";
          name = "ebk";
          userns = "keep-id:uid=1000,gid=1000";

          addHosts = [
            "auth.home.lan:host-gateway"
          ];

          environments = {
            EBK_LOG_MODE = "console file";
          };

          environmentFiles = [
            "secrets/ebk/secret-key"
            "secrets/ebk/client-key"
          ];

          volumes = [
            "/etc/localtime:/etc/localtime:ro"

            # config
            "${config.home.homeDirectory}/containers/ebk/ezbookkeeping.ini:/ezbookkeeping/conf/ezbookkeeping.ini:ro"

            # volumes
            "${volumes.ebk-data.ref}:/ezbookkeeping/storage"
            "${volumes.ebk-log.ref}:/ezbookkeeping/log"
          ];

          publishPorts = [
            "${toString ports.ebk}:8080/tcp"
          ];
        };
      };
    };
}