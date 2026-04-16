/*
  modules/containers/services/node-red.nix
  Created: 2026-04-15
*/

{
  config,
  ports,
  envSecretsPrefix,
  ...
}:
let
  nodeRedVersion = "latest";
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

    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.node-red-data.volumeConfig = {
        type = "bind";
        device = "/opt/node-red/data";
      };

      containers.node-red = {
        autoStart = true;

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/nodered/node-red:${nodeRedVersion}";
          name = "node-red";

          addHosts = [
            "git.home.lan:host-gateway"
            "papra.home.lan:host-gateway"
          ];

          environments = {
            TZ = "Europe/Berlin";

            NODE_EXTRA_CA_CERTS = "/certs/home.lan.crt";

            NODE_RED_ENABLE_PROJECTS = "true";
            NODE_RED_ENABLE_SAFE_MODE = "false";

            GIT_SSL_CAINFO = "/certs/home.lan.crt";
          };

          environmentFiles = [

          ];

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/certs/home.lan.crt:/usr/local/share/ca-certificates/home.lan.crt:ro"
            "/certs/home.lan.crt:/certs/home.lan.crt:ro"

            # volumes
            "${volumes.node-red-data.ref}:/data:U"
          ];

          publishPorts = [
            "${toString ports.node-red}:1880/tcp"
          ];
        };
      };
    };
}
