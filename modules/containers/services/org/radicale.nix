/*
  modules/containers/services/radicale.nix

  part of der-home-server
  created 2026-04-16
*/

{
  config,
  pkgs,
  ports,
  envSecretsPrefix,
  ...
}:
let
  radicaleImageVersion = "master";
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

      policy = "bypass";

      icon = "radicale";
    };

    containerConfig = {
      files."config" = {
        source = (pkgs.formats.ini { }).generate "config" radicaleSettings;
      };

      volumes = {
        radicale-data = "/opt/radicale/data";
      };
    };
  };

  age.secrets =
    let
      mkSecret = name: {
        file = ../../../../secrets/${name}.age;
        path = "${envSecretsPrefix}/${name}";
        mode = "444";
      };
    in
    {
      radicale-ldap-pw = mkSecret "ldap/s_admin-pass";
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet)
        volumes
        networks
        pods
        builds
        ;
    in
    {
      builds.radicale-image = {
        buildConfig = {
          file = "${pkgs.writeText "radicale.Dockerfile" (
            builtins.readFile ../../builds/radicale.Dockerfile
          )}";
          tag = "localhost/radicale-ldap:internal";

          buildArgs = {
            VERSION = radicaleImageVersion;
            DEPENDENCIES = "ldap";
          };
        };
      };

      volumes.radicale-data.volumeConfig = {
        type = "bind";
        device = config.myServices.radicale.containerConfig.volumes.radicale-data;
      };

      containers.radicale = {
        autoStart = true;

        unitConfig = {
          Requires = [ "radicale-image-build.service" ];
          After = [ "radicale-image-build.service" ];
        };

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "localhost/radicale-ldap:internal";
          name = "radicale";

          addHosts = [
            "ldap.home.lan:host-gateway"
            "git.home.lan:host-gateway"
          ];

          environments = {
            TZ = "Europe/Berlin";

            RADICALE_CONFIG = "/etc/radicale/config";
            GIT_SSL_CAINFO = "/certs/ca.crt";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            # config
            "${config.myServices.radicale.containerConfig.files."config".fullPath}:/etc/radicale/config:ro,U"

            # secrets
            "${config.age.secrets.radicale-ldap-pw.path}:/run/secrets/LDAP_PASSWORD:ro"

            # volumes
            "${volumes.radicale-data.ref}:/var/lib/radicale:U"
          ];

          publishPorts = [
            "${toString ports.radicale}:5232/tcp"
          ];
        };
      };
    };
}
