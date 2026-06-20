{
  config,
  pkgs,
  mkConf,
  ...
}:
mkConf {
  path = "containers/slskd/slskd.yml";
  source = (pkgs.formats.yaml {}).generate "slskd-settings" {
    directories = {
      downloads = "/download/finished";
      incomplete = "/download/incomplete";
    };

    shares = {
      directories = ["/music"];
    };

    web = {
      port = 5030;
      https = {
        disabled = false;
        port = 5031;
      };

      authentication = {
        disabled = false;
        username = "admin";
        password = "@PLACEHOLDER_WEBUI_PASS@";

        apiKeys = {
          lidarr = {
            key = "@PLACEHOLDER_LIDARR_API_KEY@";
            cidr = "0.0.0.0/0,::/0";
          };

          soularr = {
            key = "@PLACEHOLDER_SOULARR_API_KEY@";
            cidr = "0.0.0.0/0,::/0";
          };
        };
      };
    };

    soulseek = {
      address = "vps.slsknet.org";
      port = 2271;

      username = "@PLACEHOLDER_USER@";
      password = "@PLACEHOLDER_PASS@";
    };

    flags = {
      no_remote_configuration = true;
    };

    integrations = {
      vpn = {
        enabled = true;
        portForwarding = false;
        pollingInterval = 2500;
        gluetun = {
          version = 1;
          url = "http://gluetun:8888";
          auth = "apikey";
          apiKey = "@PLACEHOLDER_GLUETUN_API_KEY@";
        };
      };
    };
  };

  secrets = {
    PLACEHOLDER_GLUETUN_API_KEY = config.age.secrets.slskd-gluetun-api-key.path;
    PLACEHOLDER_LIDARR_API_KEY = config.age.secrets.slskd-lidarr-api-key.path;
    PLACEHOLDER_SOULARR_API_KEY = config.age.secrets.slskd-soularr-api-key.path;
    PLACEHOLDER_USER = config.age.secrets.slskd-user.path;
    PLACEHOLDER_PASS = config.age.secrets.slskd-pass.path;
    PLACEHOLDER_WEBUI_PASS = config.age.secrets.slskd-webui-pass.path;
  };
}
