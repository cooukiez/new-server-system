/*
  modules/containers/services/node-red.nix
  Created: 2026-04-15
*/

{
  config,
  pkgs,
  ports,
  envSecretsPrefix,
  ...
}:
let
  settingsFormat = pkgs.formats.ini { };

  radicaleVersion = "latest";

  # build image
  radicalePackageVersion = "master";
  radicaleDependencies = "ldap";

  containerFile = pkgs.writeText "Radicale.Containerfile" ''
    FROM python:3-alpine AS builder

    RUN apk add --no-cache --virtual gcc libffi-dev musl-dev \
        && python -m venv /app/venv \
        && /app/venv/bin/pip install --no-cache-dir "Radicale[${radicaleDependencies}] @ https://github.com/Kozea/Radicale/archive/${radicalePackageVersion}.tar.gz"

    FROM python:3-alpine

    WORKDIR /app

    RUN addgroup -g 1000 radicale \
        && adduser radicale --home /var/lib/radicale --system --uid 1000 --disabled-password -G radicale \
        && apk add --no-cache ca-certificates openssl curl git

    COPY --chown=radicale:radicale --from=builder /app/venv /app

    VOLUME /var/lib/radicale

    ENTRYPOINT [ "/app/bin/python", "/app/bin/radicale"]
    CMD ["--hosts", "0.0.0.0:5232,[::]:5232"]

    USER radicale
  '';

  # radicale settings
  radicaleSettings = {
    server = {
      hosts = "0.0.0.0:5232";
    };

    auth = {
      type = "ldap";
      
      ldap_uri = "ldap://ldap.home.lan:${toString ports.lldap}";
      ldap_base = "ou=people,dc=ldap,dc=home,dc=lan";
      
      ldap_reader_dn = "uid=admin,ou=people,dc=ldap,dc=home,dc=lan";
      ldap_secret_file = "/run/secrets/LDAP_PASSWORD";

      ldap_filter = "(&(objectClass=person)(memberOf=cn=users,ou=groups,dc=ldap,dc=home,dc=lan)(uid={0}))";

      ldap_user_attribute = "uid";
      ldap_groups_attribute = "memberOf";

      ldap_security = "tls";
      ldap_ssl_ca_file = "/certs/home.lan.crt";
    };

    storage = {
      filesystem_folder = "/var/lib/radicale/collections";
    };
    
    logging = {
      level = "info";
    };
  };
in
{
  home.file."containers/radicale/config" = {
    source = settingsFormat.generate "config" radicaleSettings;
  };

  age.secrets =
    let
      mkSecret = name: {
        file = ../../../secrets/${name}.age;
        path = "${envSecretsPrefix}/${name}";
      };
    in
    {
      radicale-ldap-pw = mkSecret "ldap/admin-pass";
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods builds;
    in
    {
      builds.radicale-image = {
        buildConfig = {
          file = "${containerFile}";
          tag = "localhost/radicale-ldap:latest";
        };
      };

      volumes.radicale-data.volumeConfig = {
        type = "bind";
        device = "/opt/radicale/data";
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
          image = "localhost/radicale-ldap:${radicaleVersion}";
          name = "radicale";
          user = "0:0";

          addHosts = [
            "ldap.home.lan:host-gateway"
            "git.home.lan:host-gateway"
          ];

          environments = {
            RADICALE_CONFIG = "/etc/radicale/config";

            GIT_SSL_CAINFO = "/certs/home.lan.crt";
          };

          volumes = [
            # config
            "${config.home.homeDirectory}/containers/radicale/config:/etc/radicale/config:ro"

            # secrets
            "${config.age.secrets.radicale-ldap-pw.path}:/run/secrets/LDAP_PASSWORD:ro"

            # certificates
            "/certs/home.lan.crt:/usr/local/share/ca-certificates/home.lan.crt:ro"
            "/certs/home.lan.crt:/certs/home.lan.crt:ro"

            # volumes
            "${volumes.radicale-data.ref}:/var/lib/radicale"
          ];

          publishPorts = [
            "${toString ports.radicale}:5232/tcp"
          ];
        };
      };
    };
}