/*
  modules/containers/services/org/radicale.nix

  part of der-home-server
  created 2026-04-16
*/

{
  config,
  pkgs,
  images,
  ports,
  envSecretsPrefix,
  ...
}:
let
  radicaleSettings = (import ./radicale-config.nix { inherit ports; }).radicaleSettings;
in
{
  myServices.radicale = {
    serviceConfig = {
      name = "Radicale";
      description = "Lightweight DAV Server";
      serviceType = "Apps";

      subdomain = "dav";
      port = ports.radicale;

      disableProxy = true;
      policy = "two_factor";
      group = "users";

      icon = "radicale";
    };
  };

  home.file."containers/radicale/config".source =
    (pkgs.formats.ini { }).generate "config"
      radicaleSettings;

  age.secrets =
    let
      mkSecret = name: {
        file = ../../../../secrets/${name}.age;
      };
    in
    {
      home-lan-key = mkSecret "certs/home.lan.key";
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet)
        volumes
        networks
        pods
        ;
    in
    {
      volumes.radicale-data.volumeConfig = {
        type = "bind";
        device = "/opt/radicale/data";
      };

      containers.radicale = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.radicale-original}";
          name = "radicale";

          addHosts = [
            "ldap.home.lan:host-gateway"
            "git.home.lan:host-gateway"
          ];

          environments = {
            TZ = "Europe/Berlin";

            RADICALE_CONFIG = "/config";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"
            "/certs/home.lan.crt:/certs/home.lan.crt:ro"

            # config
            "${config.home.homeDirectory}/containers/radicale/config:/config:ro,U"

            # secrets
            "${config.age.secrets.home-lan-key.path}:/run/secrets/HOME_LAN_KEY:ro"

            # volumes
            "${volumes.radicale-data.ref}:/data:U"
          ];

          publishPorts = [
            "${toString ports.radicale}:5232/tcp"
          ];
        };
      };
    };
}
