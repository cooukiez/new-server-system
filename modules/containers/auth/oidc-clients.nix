/*
  modules/containers/auth/oidc-clients.nix

  part of server system
  created 2026-04-12
*/
[
  {
    #
    # system
    #
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
      "email"
      "groups"
    ];

    response_types = [ "code" ];
    grant_types = [ "authorization_code" ];

    access_token_signed_response_alg = "RS256";
    userinfo_signed_response_alg = "none";
    token_endpoint_auth_method = "client_secret_basic";
  }

  #
  # services
  #
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
    client_id = "linkwarden";
    client_name = "Linkwarden";
    client_secret = "$pbkdf2-sha512$310000$JdzSF/citkF8uBU2cvc7hQ$a1L4OeJsiD9Fm5Ec9egEu2X0ugk9SXFnSBBfabMg46U8L5mvzwjLVi4GyNbZgLbdNfJx7TWKWigJK6gN9zEfjw";

    public = false;
    authorization_policy = "two_factor";
    require_pkce = false;
    pkce_challenge_method = "";

    redirect_uris = [
      "https://links.home.lan/api/v1/auth/callback/authelia"
    ];

    scopes = [
      "openid"
      "profile"
      "email"
      "groups"
    ];

    response_types = [ "code" ];
    grant_types = [ "authorization_code" ];

    access_token_signed_response_alg = "none";
    userinfo_signed_response_alg = "none";
    token_endpoint_auth_method = "client_secret_basic";
  }
  {
    client_id = "mail-archiver";
    client_name = "Mail-Archiver";
    client_secret = "$pbkdf2-sha512$310000$HAJtQDSok3NZE7hORA1UHg$gaMZiME5KX4El4UcsllFgLf40wz36/ANgLuI1c/NAH2eeFDOtZFmh74mVqw/yAq93ZHieMN3PoHw4A/r3oP4yw";

    public = false;
    authorization_policy = "two_factor";
    require_pkce = false;

    redirect_uris = [
      "https://mail.home.lan/oidc-signin-completed"
    ];

    scopes = [
      "openid"
      "profile"
      "email"
      "groups"
    ];

    response_types = [ "code" ];
    grant_types = [ "authorization_code" ];

    access_token_signed_response_alg = "none";
    userinfo_signed_response_alg = "none";
    token_endpoint_auth_method = "client_secret_post";
  }
  {
    client_id = "memos";
    client_name = "Memos";
    client_secret = "$pbkdf2-sha512$310000$RP9plwWlCWubeGu3X4AkFA$kJe3MFuZaLBGAFFLW9UXGbLO1BMscSbf54nOHYG7U2JjaQSwZp1GHJRWbuZCi99Qbl/lAkAoPlELAd1PdFOPhw";

    public = false;
    authorization_policy = "two_factor";
    require_pkce = false;

    redirect_uris = [
      "https://memos.home.lan/auth/callback"
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
    client_id = "opengist";
    client_name = "Opengist";
    client_secret = "$pbkdf2-sha512$310000$wX7aZ2/8eWwCdm6NRuIo9g$GZDOlfO39o9tB9m/97xbHC/HRQmXpDAlSDSgdbMsaPEpfFBvvwUhadp5I1urVltCdFe6KKp2EAA7n0vghhvVgA";

    public = false;
    authorization_policy = "two_factor";
    require_pkce = false;

    redirect_uris = [
      "https://gists.home.lan/oauth/openid-connect/callback"
    ];

    scopes = [
      "openid"
      "profile"
      "email"
      "groups"
    ];

    response_types = [ "code" ];
    grant_types = [ "authorization_code" ];

    access_token_signed_response_alg = "none";
    userinfo_signed_response_alg = "none";
    token_endpoint_auth_method = "client_secret_post";
  }
  {
    client_id = "outline";
    client_name = "Outline";
    client_secret = "$pbkdf2-sha512$310000$Tw0Q1hvxCwnE.w6HOtq5MA$8VMzgoouUbGqZSf5ofbGHtXE/2f.bYldTKbOrcmz8d2hy4M/oenTvGPC0gFIuB3gnrq6MtaZMdCQ50dGNUSBew";

    public = false;
    authorization_policy = "two_factor";
    require_pkce = false;

    redirect_uris = [
      "https://outline.home.lan/auth/oidc.callback"
    ];

    scopes = [
      "openid"
      "offline_access"
      "profile"
      "email"
    ];

    response_types = [ "code" ];
    grant_types = [
      "authorization_code"
      "refresh_token"
    ];

    access_token_signed_response_alg = "none";
    userinfo_signed_response_alg = "none";
    token_endpoint_auth_method = "client_secret_post";
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
    client_id = "trek";
    client_name = "TREK";
    client_secret = "$pbkdf2-sha512$310000$vyE3uE/bQsfUDyLCSbaTAA$AGf1SOfIuV2lEefCpuTKjNlRsJ73q/6Dbi3KVNgCBTO0vVPXir5NqfBF628R/NGMZpTkaVdJNuP/dlO3/HcV2g";

    public = false;
    authorization_policy = "two_factor";
    require_pkce = false;
    pkce_challenge_method = "";

    redirect_uris = [
      "https://trek.home.lan/api/auth/oidc/callback"
    ];

    scopes = [
      "openid"
      "profile"
      "email"
      "groups"
    ];

    response_types = [ "code" ];
    grant_types = [ "authorization_code" ];

    access_token_signed_response_alg = "none";
    userinfo_signed_response_alg = "none";
    token_endpoint_auth_method = "client_secret_post";
  }
]
