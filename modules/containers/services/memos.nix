/*
  modules/containers/services/memos.nix

  part of der-home-server
  created 2026-04-20
*/

{
  config,
  pkgs,
  ports,
  envSecretsPrefix,
  ...
}:
let
  # todo: disable non oidc login
  memosVersion = "stable";
in
{
  myServices.memos = {
    serviceConfig = {
      name = "Memos";
      description = "Lightweight Note-Taking Service";
      serviceType = "Apps";

      subdomain = "memos";
      port = ports.memos;

      policy = "bypass";

      icon = "memos";
    };
  };

  age.secrets =
    let
      mkSecret = name: {
        file = ../../../secrets/${name}.age;
        path = "${envSecretsPrefix}/${name}";
      };
    in
    { };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.memos-data.volumeConfig = {
        type = "bind";
        device = "/opt/memos/data";
      };

      containers.memos = {
        autoStart = true;

        unitConfig = {
          Requires = [ "postgres.service" ];
          After = [ "postgres.service" ];
        };

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";

          ExecStartPre = [
            "+${pkgs.writeShellScript "pre-start" ''
              ${pkgs.coreutils}/bin/mkdir -p "/opt/memos/data"
            ''}"
          ];
        };

        containerConfig = {
          image = "docker.io/neosmemo/memos:${memosVersion}";
          name = "memos";

          addHosts = [
            "auth.home.lan:host-gateway"
          ];

          environments = {
            TZ = "Europe/Berlin";

            MEMOS_PORT = "5230";
            MEMOS_DRIVER = "postgres";
            MEMOS_INSTANCE_URL = config.myServices.memos.serviceConfig.href;

            # todo: private db password
            MEMOS_DSN = "postgres://memos:memos@host.containers.internal:${toString ports.postgres}/memos?sslmode=disable";

            MEMOS_DATA = "/data";
          };

          environmentFiles = [ ];

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            "${volumes.memos-data.ref}:/data:U"
          ];

          publishPorts = [
            "${toString ports.memos}:5230/tcp"
          ];
        };
      };
    };
}
