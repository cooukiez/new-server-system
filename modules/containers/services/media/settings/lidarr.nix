{
  config,
  pkgs,
  mkConf,
  ...
}: let
  mkLidarrXml = attrs: ''
    <Config>
      ${builtins.concatStringsSep "\n  " (
      pkgs.lib.mapAttrsToList (k: v: "<${k}>${toString v}</${k}>") attrs
    )}
    </Config>
  '';
in
  mkConf {
    path = "containers/lidarr/config.xml";
    source = pkgs.writeText "lidarr-settings" (mkLidarrXml {
      InstanceName = "Lidarr";

      BindAddress = "*";
      Port = "8686";
      SslPort = "6868";

      UrlBase = "";

      EnableSsl = "False";
      SslCertPath = "";
      SslCertPassword = "";

      LaunchBrowser = "True";
      ApiKey = "@PLACEHOLDER_API_KEY@";

      AuthenticationMethod = "Forms";
      AuthenticationRequired = "Enabled";

      Branch = "nightly";
      UpdateMechanism = "Docker";

      # postgres configuration
      PostgresUser = "admin";
      PostgresPassword = "@PLACEHOLDER_DB_PASS@";

      PostgresHost = "lidarr-postgres";
      PostgresPort = "5432";

      PostgresMainDb = "lidarr-main";
      PostgresLogDb = "lidarr-log";

      LogLevel = "debug";
      AnalyticsEnabled = "False";
    });

    secrets = {
      PLACEHOLDER_API_KEY = config.age.secrets.lidarr-api-key.path;
      PLACEHOLDER_DB_PASS = config.age.secrets.lidarr-db-pass.path;
    };
  }
