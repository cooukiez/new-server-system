{
  config,
  pkgs,
  lib,
  mkConf,
  ...
}:
mkConf {
  path = "containers/soularr/config.ini";
  source = pkgs.writeText "soularr-settings" (lib.generators.toINI {} {
    Lidarr = {
      api_key = "@PLACEHOLDER_LIDARR_API_KEY@";
      host_url = "http://lidarr:8686";
      download_dir = "/download/slskd/finished";
      disable_sync = "False";
    };

    Slskd = {
      api_key = "@PLACEHOLDER_SLSKD_API_KEY@";
      host_url = "http://slskd:5030";

      url_base = "/";
      download_dir = "/download/finished";

      delete_searches = "False";
      stalled_timeout = 3600;
    };

    "Release Settings" = {
      use_most_common_tracknum = "True";
      allow_multi_disc = "True";

      accepted_countries = ""; # "[Worldwide],Germany,Europe,United States,Japan,United Kingdom,Australia,Canada";
      accepted_formats = ""; # "CD,Digital Media,Vinyl";
    };

    "Search Settings" = {
      search_timeout = 5000;

      maximum_peer_queue = 50;
      minimum_peer_upload_speed = 0;
      minimum_filename_match_ratio = 0.8;

      allowed_filetypes = "flac 24/192,flac 16/44.1,flac,mp3 320,mp3";

      ignored_users = "";

      search_for_tracks = "True";
      album_prepend_artist = "False";
      track_prepend_artist = "True";

      search_type = "incrementing_page";

      number_of_albums_to_grab = 10;
      remove_wanted_on_failure = "False";

      title_blacklist = "";

      search_source = "missing";
    };

    Logging = {
      level = "INFO";
      format = "[%(levelname)s|%(module)s|L%(lineno)d] %(asctime)s: %(message)s";
      datefmt = "%Y-%m-%dT%H:%M:%S%z";
    };
  });

  secrets = {
    PLACEHOLDER_LIDARR_API_KEY = config.age.secrets.soularr-lidarr-api-key.path;
    PLACEHOLDER_SLSKD_API_KEY = config.age.secrets.soularr-slskd-api-key.path;
  };
}
