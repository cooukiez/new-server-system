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
      # node-red-secret = mkSecret "node-red-secret";
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes;
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
          
          # default user 1000:1000
          uidMaps = [ "1000:0:1" ];
          gidMaps = [ "1000:0:1" ];

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
            # "secrets/node-red-secret"
          ];

          volumes = [
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/certs/home.lan.crt:/usr/local/share/ca-certificates/home.lan.crt:ro"
            "/certs/home.lan.crt:/certs/home.lan.crt:ro"

            # volumes
            "${volumes.node-red-data.ref}:/data"
          ];

          publishPorts = [
            "${toString ports.node-red}:1880/tcp"
          ];
        };
      };
    };
}