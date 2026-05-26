/*
modules/containers/services/business/radicale.nix

part of server system
created 2026-05-13 by ludw
*/
{
  config,
  pkgs,
  images,
  ports,
  ...
}: let
  radicaleSettings = (import ./radicale-config.nix {inherit ports;}).radicaleSettings;
in {
  myServices.radicale = {
    serviceConfig = {
      name = "Radicale";
      description = "Lightweight DAV Server";
      serviceType = "Apps";

      subdomain = "dav";
      port = ports.radicale;

      disableProxy = true;
      policy = "bypass";

      icon = "radicale";
    };
  };

  home.file."containers/radicale/config".source =
    (pkgs.formats.ini {}).generate "radicale-settings"
    radicaleSettings;

  age.secrets = let
    mkSecret = name: {
      file = ../../../../secrets/${name}.age;
      mode = "444";
    };
  in {
    radicale-crt-key = mkSecret "certs/home-lan-key";
    radicale-ldap-pass = mkSecret "auth/ldap/s_admin-pass";
  };

  virtualisation.quadlet = let
    inherit
      (config.virtualisation.quadlet)
      volumes
      ;
  in {
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

          # extra certificates
          "/certs/home.lan.crt:/certs/home.lan.crt:ro"
          "${config.age.secrets.radicale-crt-key.path}:/run/secrets/HOME_LAN_KEY:ro"
          "${config.age.secrets.radicale-ldap-pass.path}:/run/secrets/LDAP_PASSWORD:ro"

          # config
          "${config.home.homeDirectory}/containers/radicale/config:/config:ro,U"

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
