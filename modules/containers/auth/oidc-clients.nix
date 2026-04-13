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
  /*
    {
      client_id = "jellyfin";
      client_name = "Jellyfin";

      client_secret = "$pbkdf2-sha512$310000$Je6PMm6qXhiCWQAQbndJvA$.UPCWR6HyidsVVI8hLgmDP9NYlL4pCfqcbwPuHxdbmd07dGFseLpbAunsJXvTA12Jvbn4IL/w3ZNSZVS5dAtCg";

      public = false;
      authorization_policy = "two_factor";
      require_pkce = true;
      pkce_challenge_method = "S256";

      redirect_uris = [
        "https://jellyfin.home.lan/sso/OID/redirect/authelia"
      ];

      scopes = [
        "openid"
        "profile"
        "groups"
      ];

      response_types = [ "code" ];
      grant_types = [ "authorization_code" ];

      access_token_signed_response_alg = "none";
      userinfo_signed_response_alg = "none";
      token_endpoint_auth_method = "client_secret_post";
    }
  */
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
    client_secret = "$pbkdf2-sha512$310000$6Jkj5q/W48sCg8ZUFoAlWQ$2INpYddG8oxYX0nrvKQ2w.siUbj5qOlolvGs9NiK9GKFSx56CRYWR7E9qpisjOUtGyBCxZwboseUSh2ki6isig";

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
]
