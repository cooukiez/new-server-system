/*
  modules/containers/services/stirling.nix

  part of der-home-server
  created 2026-04-19
*/

{
  config,
  pkgs,
  images,
  ports,
  ...
}:
{
  myServices.stirling = {
    serviceConfig = {
      name = "Stirling-PDF";
      description = "PDF Editing Tool";
      serviceType = "Apps";

      subdomain = "pdf";
      port = ports.stirling;

      policy = "one_factor";
      group = "users";

      icon = "stirling-pdf";
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.stirling-config.volumeConfig = {
        type = "bind";
        device = "/opt/stirling/config";
      };

      volumes.stirling-tessdata.volumeConfig = {
        type = "bind";
        device = "/opt/stirling/tessdata";
      };

      volumes.stirling-pipeline.volumeConfig = {
        type = "bind";
        device = "/opt/stirling/pipeline";
      };

      volumes.stirling-log.volumeConfig = {
        type = "bind";
        device = "/opt/stirling/log";
      };

      containers.stirling = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";

          ExecStartPre = [
            "+${pkgs.writeShellScript "pre-stirling" ''
              ${pkgs.coreutils}/bin/mkdir -p "/opt/stirling/config"
              ${pkgs.coreutils}/bin/mkdir -p "/opt/stirling/tessdata"
              ${pkgs.coreutils}/bin/mkdir -p "/opt/stirling/pipeline"
              ${pkgs.coreutils}/bin/mkdir -p "/opt/stirling/log"
            ''}"
          ];
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.stirling}";
          name = "stirling";

          environments = {
            TZ = "Europe/Berlin";
            LANGS = "en_US";

            SECURITY_ENABLELOGIN = "false";
            INSTALL_BOOK_AND_ADVANCED_HTML_OPS = "true";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            "${volumes.stirling-config.ref}:/configs"
            "${volumes.stirling-tessdata.ref}:/usr/share/tessdata"
            "${volumes.stirling-pipeline.ref}:/pipeline"
            "${volumes.stirling-log.ref}:/logs"
          ];

          publishPorts = [
            "${toString ports.stirling}:8080/tcp"
          ];
        };
      };
    };
}
