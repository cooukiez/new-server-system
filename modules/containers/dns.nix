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
      volumes.adguard-work.volumeConfig = {
        type = "bind";
        device = "/opt/adguardhome/work";
      };
      volumes.adguard-conf.volumeConfig = {
        type = "bind";
        device = "/opt/adguardhome/conf";
      };

      containers.adguardhome = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/adguard/adguardhome:latest";

          addCapabilities = [
            "NET_ADMIN"
            "NET_BIND_SERVICE"
          ];

          volumes = [
            "${volumes.adguard-work.ref}:/opt/adguardhome/work"
            "${volumes.adguard-conf.ref}:/opt/adguardhome/conf"
          ];

          /*
            publishPorts = [
              "127.0.0.1:53:53/tcp"
              "127.0.0.1:53:53/udp"
              "127.0.0.1:3000:3000/tcp"
              "127.0.0.1:80:80/tcp"
            ];
          */

          # userns = "keep-id";
        };
      };
    };
}
