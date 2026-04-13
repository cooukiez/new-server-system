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
}
