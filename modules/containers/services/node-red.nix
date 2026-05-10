/*
  modules/containers/services/node-red.nix

  part of der-home-server
  created 2026-04-19
*/

{
  config,
  pkgs,
  ports,
  envSecretsPrefix,
  ...
}:
let
  nodeRedVersion = "latest";
in
{
  myServices.nodeRed = {
    serviceConfig = {
      name = "Node-RED";
      description = "Automation Flow System";
      serviceType = "Services";

      subdomain = "flow";
      port = ports.nodeRed;

      policy = "one_factor";
      group = "admins";

      icon = "https://avatars.githubusercontent.com/u/5375661?s=48&v=4";
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
      volumes.node-red-data.volumeConfig = {
        type = "bind";
        device = "/opt/node-red/data";
      };

      containers.node-red = {
        autoStart = true;

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";

          ExecStartPre = [
            "+${pkgs.writeShellScript "pre-start" ''
              ${pkgs.coreutils}/bin/mkdir -p "/opt/node-red/data"
            ''}"
          ];
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

            NODE_EXTRA_CA_CERTS = "/certs/ca.crt";

            NODE_RED_ENABLE_PROJECTS = "true";
            NODE_RED_ENABLE_SAFE_MODE = "false";

            GIT_SSL_CAINFO = "/certs/ca.crt";
          };

          environmentFiles = [ ];

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            # volumes
            "${volumes.node-red-data.ref}:/data:U"
          ];

          publishPorts = [
            "${toString ports.nodeRed}:1880/tcp"
          ];
        };
      };
    };
}
