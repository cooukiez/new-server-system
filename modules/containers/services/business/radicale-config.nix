/*
  modules/containers/services/business/radicale-config.nix

  part of server system
  created 2026-05-11
*/

{
  ports,
  ...
}:
{
  # https://github.com/tomsquest/docker-radicale/blob/3f35011e6ff560acb78b42437ec1bdad35c592b8/config
  radicaleSettings = {
    server = {
      hosts = "0.0.0.0:5232";
      max_connections = 8;

      delay_on_error = 1;
      max_content_length = 100000000;
      max_resource_size = 10000000;
      timeout = 30;

      ssl = false;
      certificate = "/certs/home.lan.crt";
      key = "/run/secrets/HOME_LAN_KEY";
      certificate_authority = "/certs/ca.crt";

      protocol = "";
      ciphersuite = "";
      script_name = "";
      # validate_user_value = "minimal";
      # validate_path_value = "minimal";
    };

    encoding = {
      request = "utf-8";
      stock = "utf-8";
    };

    auth = {
      type = "http_x_remote_user";

      # cache_logins = false;
      # cache_successful_logins_expiry = 15;
      # cache_failed_logins_expiry = 90;

      # ldap setup
      ldap_uri = "ldap://ldap.home.lan:${toString ports.lldap}";
      ldap_base = "ou=people,dc=ldap,dc=home,dc=lan";

      ldap_reader_dn = "uid=admin,ou=people,dc=ldap,dc=home,dc=lan";
      ldap_secret_file = "/run/secrets/LDAP_PASSWORD";

      ldap_filter = "(&(objectClass=person)(memberOf=cn=users,ou=groups,dc=ldap,dc=home,dc=lan)(uid={0}))";

      ldap_user_attribute = "uid";
      ldap_groups_attribute = "memberOf";

      ldap_security = "tls";
      ldap_ssl_verify_mode = "REQUIRED";
      ldap_ssl_ca_file = "/certs/ca.crt";

      # ldap_group_members_attribute = "";
      # ldap_group_base = "";
      # ldap_group_filter = "";

      # ldap_ignore_attribute_create_modify_timestamp = false;

      # dovecot_connection_type = "AF_UNIX";
      # dovecot_socket = "/var/run/dovecot/auth-client";
      # dovecot_host = "localhost";
      # dovecot_port = 143;

      # remote_ip_source = "REMOTE_ADDR";
      # imap_host = "localhost";
      # imap_security = "tls";

      # oauth2_token_endpoint = "<URL>";
      # oauth2_client_id = "radicale";
      # oauth2_client_secret = "";

      # pam_service = "radicale";
      # pam_group_membership = "";

      # htpasswd_filename = "/etc/radicale/users";
      # htpasswd_encryption = "autodetect";
      # htpasswd_cache = false;

      # delay = 1;
      # realm = "Radicale - Password Required";

      # lc_username = false;
      # strip_domain = false;
      # urldecode_username = false;
    };

    rights = {
      # type = "owner_only";
      # file = "/etc/radicale/rights";
      # permit_delete_collection = true;
      # permit_overwrite_collection = true;
    };

    storage = {
      # type = "multifilesystem";

      filesystem_folder = "/data/collections";

      # filesystem_cache_folder = "";

      # use_cache_subfolder_for_item = false;
      # use_cache_subfolder_for_history = false;
      # use_cache_subfolder_for_synctoken = false;
      # use_mtime_and_size_for_item_cache = false;

      # folder_umask = "";

      # max_sync_token_age = 2592000;
      # skip_broken_item = true;

      # strict_preconditions = false;

      # hook = "";
      # predefined_collections = "";
    };

    sharing = {
      # type = "none";

      # database_path = "";
      # collection_by_token = false;
      # collection_by_map = false;

      # permit_create_token = false;
      # permit_create_map = false;
      # permit_properties_overlay = false;

      # enforce_properties_overlay = true;

      # default_permissions_create_token = "rp";
      # default_permissions_create_map = "r";
    };

    web = {
      # type = "internal";
    };

    logging = {
      level = "info";

      # limit_content = 3000;
      # trace_filter = "";

      mask_passwords = true;

      # bad_put_request_content = false;

      # backtrace_on_debug = false;
      # request_header_on_debug = false;
      # request_content_on_debug = false;
      # response_header_on_debug = false;
      # response_content_on_debug = false;
      # rights_rule_doesnt_match_on_debug = false;
      # storage_cache_actions_on_debug = false;

      # profiling = "none";
      # profiling_per_request_min_duration = 3;
      # profiling_per_request_header = false;
      # profiling_per_request_xml = false;
      # profiling_per_request_method_interval = 600;
      # profiling_top_x_functions = 10;
    };

    headers = {
      # "Access-Control-Allow-Origin" = "*";
      # "Content-Security-Policy" = "default-src 'self'; object-src 'none'";
    };

    hook = {
      # type = "none";
      # dryrun = false;

      # rabbitmq_endpoint = "";
      # rabbitmq_topic = "";
      # rabbitmq_queue_type = "classic";

      # smtp_server = "localhost";
      # smtp_port = 25;
      # smtp_security = "starttls";
      # smtp_ssl_verify_mode = "REQUIRED";
      # smtp_username = "";
      # smtp_password = "";

      # from_email = "";
      # mass_email = false;

      # new_or_added_to_event_template = "";
      # deleted_or_removed_from_event_template = "";
      # updated_event_template = "";
    };

    reporting = {
      # max_freebusy_occurrence = 10000;
    };
  };
}
