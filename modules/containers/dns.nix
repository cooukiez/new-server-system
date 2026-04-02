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
      volumes.adguard-conf.volumeConfig = {
        type = "bind";
        device = "/opt/adguardhome/conf";
      };

      volumes.adguard-work.volumeConfig = {
        type = "bind";
        device = "/opt/adguardhome/work";
      };
      
      containers.adguardhome = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "ghcr.io/adguard/adguardhome:latest";

          volumes = [
            "${volumes.adguard-conf.ref}:/opt/adguardhome/conf"
            "${volumes.adguard-work.ref}:/opt/adguardhome/work"
          ];

          publishPorts = [
            "127.0.0.1:53:53/tcp"
            "127.0.0.1:53:53/udp"
            "127.0.0.1:3000:3000/tcp"
            "127.0.0.1:80:80/tcp"
          ];

          # userns = "keep-id";
        };
      };
    };
}
