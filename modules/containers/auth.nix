{
  config,
  ...
}:
{
  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.authelia-config.volumeConfig = {
        type = "bind";
        device = "/opt/authelia/config";
      };

      containers.authelia = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/authelia/authelia:latest";

          volumes = [
            "${volumes.authelia-config.ref}:/config"
          ];
        };
      };
    };
}
