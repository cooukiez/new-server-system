/*
  modules/containers/auth/oidc-client-configs.nix

  part of der-home-server
  created 2026-04-12
*/

{
  grafana = {
    enabled = true;
    name = "Authelia";
    icon = "signin";

    client_id = "grafana";
    client_secret = "$__file{/run/secrets/AUTH_GRAFANA_OIDC}";

    scopes = "openid profile email groups";
    empty_scopes = false;

    auth_url = "https://auth.home.lan/api/oidc/authorization";
    token_url = "https://auth.home.lan/api/oidc/token";
    api_url = "https://auth.home.lan/api/oidc/userinfo";

    login_attribute_path = "preferred_username";
    groups_attribute_path = "groups";
    name_attribute_path = "name";
    allow_assign_grafana_admin = true;

    use_pkce = true;
    auth_style = "InHeader";

    tls_client_ca = "/certs/home.lan.crt";

    role_attribute_path = "contains(groups, 'admins') && 'Admin' || contains(groups, 'editors') && 'Editor' || 'Viewer'";
  };

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
}
