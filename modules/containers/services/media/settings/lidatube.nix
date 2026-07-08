/*
modules/containers/services/media/settings/lidatube.nix

part of server system
created 2026-06-25 by ludw
*/
{
  config,
  mkEnv,
  ...
}:
mkEnv {
  path = "containers/lidatube/env";
  vars = {
    lidarr_address = "http://lidarr:8686";

    lidarr_api_key = "@PLACEHOLDER_LIDARR_API_KEY@";
    lidarr_api_timeout = "120";

    library_scan_on_completion = "True";
    preferred_codec = "mp3";
    attempt_lidarr_import = "True";
  };

  secrets = {
    PLACEHOLDER_LIDARR_API_KEY = config.age.secrets.lidarr-api-key.path;
  };
}
