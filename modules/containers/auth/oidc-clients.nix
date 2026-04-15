/*
  modules/containers/auth/oidc-clients.nix

  part of der-home-server
  created 2026-04-12
*/

[
  {
    client_id = "immich";
    client_name = "Immich";
    client_secret = "$pbkdf2-sha512$310000$X5CgmGSCM2XEmtT0jqohVA$H8TqZ1CSfnrr8M.zzjO7VAuNQtaZf2saqVBwCrTzNeHlVpaAhuQV8nhNUJ8p8jktsvT7oJBdsHa7ftQfbGynVQ";

    public = false;
    authorization_policy = "two_factor";
    require_pkce = false;

    redirect_uris = [
      "https://immich.home.lan/auth/login"
      "https://immich.home.lan/user-settings"
      "app.immich:///oauth-callback"
    ];

    scopes = [
      "openid"
      "profile"
      "email"
    ];

    response_types = [ "code" ];
    grant_types = [ "authorization_code" ];

    access_token_signed_response_alg = "none";
    userinfo_signed_response_alg = "none";
    token_endpoint_auth_method = "client_secret_post";
  }
  {
    client_id = "grafana";
    client_name = "Grafana";
    client_secret = "$pbkdf2-sha512$310000$j//xOaGDVHfltGPTrdpXAg$cjNHWiElFa8S2PlanW1.5BzjgBYsev2POF.LPdPzYGgabkC.HNEUZbP4Rs2GfpONTmIS/WcVgjDpZAlIW5FtdQ";

    claims_policy = "grafana";

    public = false;
    authorization_policy = "two_factor";
    require_pkce = true;
    pkce_challenge_method = "S256";

    redirect_uris = [
      "https://monitor.home.lan/login/generic_oauth"
    ];

    scopes = [
      "openid"
      "profile"
      "groups"
      "email"
    ];

    response_types = [ "code" ];
    grant_types = [ "authorization_code" ];

    access_token_signed_response_alg = "RS256";
    userinfo_signed_response_alg = "none";
    token_endpoint_auth_method = "client_secret_basic";
  }
  {
    client_id = "gitea";
    client_name = "Gitea";
    client_secret = "$pbkdf2-sha512$310000$PFdvvf6wivFGVmYmQULNUQ$i1jEXENP/h.xlx6pYYT4czQr7G4oqFVgf3hqJUBiNlqvty9cs5DdwufgvGDtesxkAUT7hKX4NaLSAAv6RJCKmQ";

    public = false;
    authorization_policy = "two_factor";
    require_pkce = false;
    pkce_challenge_method = "";

    redirect_uris = [
      "https://git.home.lan/user/oauth2/authelia/callback"
    ];

    scopes = [
      "openid"
      "profile"
      "email"
    ];

    response_types = [ "code" ];
    grant_types = [ "authorization_code" ];

    access_token_signed_response_alg = "none";
    userinfo_signed_response_alg = "none";
    token_endpoint_auth_method = "client_secret_basic";
  }
  {
    client_id = "papra";
    client_name = "Papra";
    client_secret = "$pbkdf2-sha512$310000$iZcRHLNCaLQRucCZQiaSpQ$uxJSCJi1ZmpwwVUjA2BCjSbLvl34KVFnv2N11wWSTUupDkucRGnXbIvNU/v00ln9cogBVl2DMiWcicYa7IeS3w";

    public = false;
    authorization_policy = "two_factor";
    require_pkce = false;
    pkce_challenge_method = "";

    redirect_uris = [
      "https://papra.home.lan/api/auth/oauth2/callback/authelia"
    ];

    scopes = [
      "openid"
      "profile"
      "email"
    ];

    response_types = [ "code" ];
    grant_types = [ "authorization_code" ];

    access_token_signed_response_alg = "none";
    userinfo_signed_response_alg = "none";
    token_endpoint_auth_method = "client_secret_post";
  }
  {
    client_id = "ezbookkeeping";
    client_name = "ezBookkeeping";
    client_secret = "$pbkdf2-sha512$310000$W7MPEUwmQzHXWrMF3IAN/A$PqcNQkyzkLHFbqeNQmglL13dVKGqv5VAocgcb/w2VXYrojUB7tKPqA6QvqmIFzkQ9RmVfzrRXEQZaHjqTiLGnw";

    public = false;
    authorization_policy = "two_factor";
    require_pkce = true;
    pkce_challenge_method = "S256";

    redirect_uris = [
      "https://finance.home.lan/oauth2/callback"
    ];

    scopes = [
      "openid"
      "profile"
      "email"
    ];

    response_types = [ "code" ];
    grant_types = [ "authorization_code" ];

    access_token_signed_response_alg = "none";
    userinfo_signed_response_alg = "none";
    token_endpoint_auth_method = "client_secret_basic";
  }
]
