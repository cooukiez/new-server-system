/*
  modules/containers/services/org/ebk-config.nix

  part of der-home-server
  created 2026-04-20
*/

{
  config,
  ports,
  ...
}:
{
  # https://github.com/mayswind/ezbookkeeping/blob/e6c6d021124566325cdbafeb70616378dc9654f7/conf/ezbookkeeping.ini#L4
  ebkSettings = {
    global = {
      mode = "production";
    };

    server = {
      protocol = "http";
      http_addr = "0.0.0.0";
      http_port = 8080;

      domain = config.myServices.ebk.serviceConfig.domain;
      root_url = config.myServices.ebk.serviceConfig.href;
      static_root_path = "public";

      cert_file = "";
      cert_key_file = "";
      unix_socket = "";

      enable_gzip = true;

      log_request = true;
      request_id_header = true;
    };

    mcp = {
      enable_mcp = false;
      mcp_allowed_remote_ips = "";
    };

    database = {
      type = "postgres";
      host = "host.containers.internal:${toString ports.postgres}";
      ssl_mode = "disable";

      # todo: private db password
      name = "ebk";
      user = "ebk";
      passwd = "ebk";

      auto_update_database = true;

      max_idle_conn = 2;
      max_open_conn = 0;
      conn_max_lifetime = 1440;

      log_query = false;

      db_path = "";
    };

    mail = {
      enable_smtp = false;

      smtp_host = "127.0.0.1:25";
      smtp_user = "";
      smtp_passwd = "";

      smtp_skip_tls_verify = false;

      from_address = "";
    };

    log = {
      mode = "console file";
      level = "info";

      log_path = "log/ezbookkeeping.log";
      request_log_path = "";
      query_log_path = "";

      log_file_rotate = false;
      log_file_max_size = 104857600;
      log_file_max_days = 7;
    };

    storage = {
      type = "local_filesystem";
      local_filesystem_path = "storage/";
      # ignore minio and webdav
    };

    llm = {
      transaction_from_ai_image_recognition = false;
      max_ai_recognition_picture_size = 10485760;
    };

    llm_image_recognition = {
      llm_provider = "";
      # ignore llm options
    };

    uuid = {
      generator_type = "internal";
      server_id = "0";
    };

    duplicate_checker = {
      checker_type = "in_memory";
      cleanup_interval = 60;
      duplicate_submissions_interval = 300;
    };

    cron = {
      enable_remove_expired_tokens = true;
      enable_create_scheduled_transaction = true;
    };

    security = {
      token_expired_time = 2592000;
      token_min_refresh_interval = 86400;
      temporary_token_expired_time = 300;

      email_verify_token_expired_time = 3600;
      password_reset_token_expired_time = 3600;

      enable_api_token = false;

      api_token_allowed_remote_ips = "";
      max_failures_per_ip_per_minute = 5;
      max_failures_per_user_per_minute = 5;
    };

    auth = {
      enable_internal_auth = false;
      enable_oauth2_auth = true;
      # enable_two_factor = true;

      enable_forget_password = false;
      forget_password_require_email_verify = false;

      oauth2_provider = "oidc";
      oauth2_client_id = "ezbookkeeping";

      oauth2_user_identifier = "email";
      oauth2_use_pkce = true;
      oauth2_auto_register = true;

      oauth2_state_expired_time = 300;
      oauth2_request_timeout = 10000;

      oauth2_proxy = "system";
      oauth2_skip_tls_verify = false;

      oidc_provider_base_url = "https://auth.home.lan";
      oidc_provider_check_issuer_url = true;

      enable_oidc_display_name = true;
      oidc_custom_display_name = "Authelia";

      # unused
      nextcloud_base_url = "";
      gitea_base_url = "";
    };

    user = {
      enable_register = true;

      enable_email_verify = false;
      enable_force_email_verify = false;

      enable_transaction_picture = true;
      max_transaction_picture_size = 10485760;
      enable_scheduled_transaction = true;

      avatar_provider = "internal";
      max_user_avatar_size = 1048576;
      default_feature_restrictions = "";
    };

    data = {
      enable_import = true;
      enable_export = true;
      max_import_file_size = 10485760;
    };

    tip = {
      enable_tips_in_login_page = false;
      login_page_tips_content = "";
    };

    notification = {
      enable_notification_after_register = false;
      after_register_notification_content = "";
      enable_notification_after_login = false;
      after_login_notification_content = "";
      enable_notification_after_open = false;
      after_open_notification_content = "";
    };

    map = {
      map_provider = "openstreetmap";
      map_data_fetch_proxy = false;

      proxy = "system";

      tomtom_map_api_key = "";
      tianditu_map_app_key = "";
      google_map_api_key = "";
      baidu_map_ak = "";

      amap_application_key = "";
      amap_security_verification_method = "internal_proxy";
      amap_application_secret = "";
      amap_api_external_proxy_url = "";

      custom_map_tile_server_url = "";
      custom_map_tile_server_annotation_url = "";
      custom_map_tile_server_min_zoom_level = 1;
      custom_map_tile_server_max_zoom_level = 18;
      custom_map_tile_server_default_zoom_level = 14;
    };

    exchange_rates = {
      data_source = "euro_central_bank";
      request_timeout = 10000;
      proxy = "system";
      skip_tls_verify = false;
    };
  };
}
