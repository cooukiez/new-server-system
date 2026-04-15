/*
  modules/containers/services/node-red.nix
  Created: 2026-04-15
*/

{
  config,
  ports,
  ...
}:
let
  nodeRedVersion = "latest";
in
{
  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes;
    in
    {
      volumes.nodered-data.volumeConfig = {
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

          environments = {
            TZ = "Europe/Berlin";

            NODE_RED_ENABLE_PROJECTS = "true";
            NODE_RED_ENABLE_SAFE_MODE = "false";
          };

          volumes = [
            "/etc/localtime:/etc/localtime:ro"

            "${volumes.nodered-data.ref}:/data"
          ];

          publishPorts = [
            "${toString ports.node-red}:1880/tcp"
          ];
        };
      };
    };
}