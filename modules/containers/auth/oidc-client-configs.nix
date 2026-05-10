/*
  modules/containers/auth/oidc-client-configs.nix

  part of der-home-server
  created 2026-04-16
*/

{
  #
  # monitoring
  #

  #
  # services
  #
  ebk = {
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
  };

  opengist = {
    provider-name = "authelia";
    client-key = "opengist";
    discovery-url = "https://auth.home.lan/.well-known/openid-configuration";

    group-claim-name = "groups";
    admin-group = "admins";
  };
}
