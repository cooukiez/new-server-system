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
      volumes.netdata-config.volumeConfig = {
        type = "bind";
        device = "/opt/netdata/config";
      };

      volumes.netdata-lib.volumeConfig = {
        type = "bind";
        device = "/opt/netdata/lib";
      };

      volumes.netdata-cache.volumeConfig = {
        type = "bind";
        device = "/opt/netdata/cache";
      };

      containers.netdata = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/netdata/netdata:latest";
          name = "netdata";
          hostname = "%H";

          volumes = [
            "${volumes.netdata-config.ref}:/etc/netdata"
            "${volumes.netdata-lib.ref}:/var/lib/netdata"
            "${volumes.netdata-cache.ref}:/var/cache/netdata"
            
            "/etc/passwd:/host/etc/passwd:ro"
            "/etc/group:/host/etc/group:ro"
            "/etc/localtime:/etc/localtime:ro"
            "/proc:/host/proc:ro"
            "/sys:/host/sys:ro"
            "/etc/os-release:/host/etc/os-release:ro"

            "/var/log/journal:/var/log/journal:ro"
            "/run/log/journal:/run/log/journal:ro"
            
            "%t/podman/podman.sock:/var/run/docker.sock:ro"
          ];

          publishPorts = [
            "19999:19999/tcp"
          ];

          appArmor = "unconfined";
          unmask = "/proc/*:/sys/*";
        };
      };
    };
}