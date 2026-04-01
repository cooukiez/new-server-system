{
  config,
  ...
}:
{
  imports = [

  ];

  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) volumes networks pods;
  in {
    volumes.adguard-work.volumeConfig = {
      type = "bind";
      device = "/opt/adguardhome/work";
    };
    volumes.adguard-conf.volumeConfig = {
      type = "bind";
      device = "/opt/adguardhome/conf";
    };

    networks = {
        internal.networkConfig.subnets = [ "10.1.1.1/24" ];
    };

    pods = {
        core = { };
    };

    containers.adguardhome = {
      autoStart = true;
      serviceConfig = {
        Restart = "always";
        RestartSec = "10";
      };

      containerConfig = {
        image = "docker.io/adguard/adguardhome:latest";
        networks = [ "podman" networks.internal.ref ];

        volumes = [
          "${volumes.adguard-work.ref}:/opt/adguardhome/work"
          "${volumes.adguard-conf.ref}:/opt/adguardhome/conf"
        ];

        publishPorts = [
          "53:53/tcp"
          "53:53/udp"
          "3000:3000/tcp"
          "80:80/tcp"
        ];
      };
    };
  };
}
