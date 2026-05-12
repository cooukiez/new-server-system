/*
  modules/containers/services/gitea.nix

  part of der-home-server
  created 2026-04-14
*/

{
  config,
  pkgs,
  images,
  ports,
  mkEnv,
  ...
}:
let
  createEnv = mkEnv {
    path = "containers/gitea/env";
    vars = {
      GITEA__database__DB_TYPE = "postgres";
      GITEA__database__HOST = "host.containers.internal:${toString ports.postgres}";
      GITEA__database__NAME = "gitea";
      GITEA__database__USER = "gitea";
      GITEA__database__PASSWD = "@PLACEHOLDER_DB_PASS@";
    };

    secrets = {
      # "PLACEHOLDER_DB_PASS" = config.age.secrets.gitea-db-pass.path;
      "PLACEHOLDER_DB_PASS" = pkgs.writeText "db-pass" "gitea";
    };

    mode = "644";
  };
in
{
  myServices.gitea = {
    serviceConfig = {
      name = "Gitea";
      description = "Selfhosted DevOps Platform";
      serviceType = "Apps";

      subdomain = "git";
      port = ports.giteaHttp;

      policy = "bypass";

      icon = "gitea";
    };
  };

  age.secrets =
    let
      mkSecret = name: {
        file = ../../../secrets/containers/gitea/${name}.age;
      };
    in
    {
      gitea-db-pass = mkSecret "s_db-pass";
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.gitea-data.volumeConfig = {
        type = "bind";
        device = "/opt/gitea/data";
      };

      containers.gitea = {
        autoStart = true;

        unitConfig = {
          Requires = [ "postgres.service" ];
          After = [ "postgres.service" ];
        };

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";

          ExecStartPre = [
            "+${pkgs.writeShellScript "pre-gitea" ''
              ${createEnv}
            ''}"
          ];
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.gitea}";
          name = "gitea";

          addHosts = [
            "auth.home.lan:host-gateway"
          ];

          environments = {
            TZ = "Europe/Berlin";
          };

          environmentFiles = [
            "env/containers/gitea/env"
          ];

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            # volumes
            "${volumes.gitea-data.ref}:/data:U"
          ];

          publishPorts = [
            "${toString ports.giteaHttp}:3000/tcp"
            "${toString ports.gitea}:22/tcp"
          ];
        };
      };
    };
}
