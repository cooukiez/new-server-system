/*
  modules/containers/services/stirling-pdf.nix
  Stirling-PDF - Local hosted web based PDF editor
*/

{
  config,
  ports,
  ...
}:
let
  stirlingVersion = "latest";
in
{
  myServices.stirling = {
    serviceConfig = {
      description = "PDF Editing Tool";
      serviceType = "Apps";

      subdomain = "pdf";
      port = ports.stirling;

      policy = "one_factor";
      group = "users";

      icon = "stirling-pdf";
    };

    containerConfig = {
      volumes = {
        stirling-config = "/opt/stirling/config";
        stirling-tessdata = "/opt/stirling/tessdata";
        stirling-pipeline = "/opt/stirling/pipeline";
        stirling-log = "/opt/stirling/log";
      };
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.stirling-config.volumeConfig = {
        type = "bind";
        device = config.myServices.stirling.containerConfig.volumes.stirling-config;
      };

      volumes.stirling-tessdata.volumeConfig = {
        type = "bind";
        device = config.myServices.stirling.containerConfig.volumes.stirling-tessdata;
      };

      volumes.stirling-pipeline.volumeConfig = {
        type = "bind";
        device = config.myServices.stirling.containerConfig.volumes.stirling-pipeline;
      };

      volumes.stirling-log.volumeConfig = {
        type = "bind";
        device = config.myServices.stirling.containerConfig.volumes.stirling-log;
      };

      containers.stirling = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/stirlingtools/stirling-pdf:${stirlingVersion}";
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
