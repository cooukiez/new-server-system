/*
  secrets/secrets.nix

  part of der-home-server
  created 2026-04-20
*/

let
  rootLaptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOe6C64fZmVmZN1uQSJexFBoQRFaQXOpfg9piE+r8cdQ";

  # server keys
  globalAgenix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLYP9AEQNvEpIWqqYlde4ncByUw6CQkamKJhc9UeSaC";

  adminUser = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGqloF2EAQJl6bwdOBhMXvkund47pwRzIQC8KMaiBEbK admin@dhs";
  dhsServer = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID7ao1FUxiK3WeHSeVsxlrIMWlFJVsHndjadOxzP4taE root@dhs";

  serverKeys = [
    globalAgenix

    adminUser
    dhsServer
  ];

  allKeys = [
    rootLaptop

    globalAgenix

    adminUser
    dhsServer
  ];
in
{
  /*
    s_ = normal secret
    e_ = secret combined with environment variable
  */

  #
  # auth
  #
  "auth/s_jwt-secret.age".publicKeys = allKeys;
  "auth/s_mail-smtp.age".publicKeys = allKeys;
  "auth/s_oidc-hmac.age".publicKeys = allKeys;
  "auth/s_oidc-jwk.age".publicKeys = allKeys;
  "auth/s_session.age".publicKeys = allKeys;
  "auth/s_storage-key.age".publicKeys = allKeys;

  # ldap
  "auth/ldap/s_admin-pass.age".publicKeys = allKeys;
  "auth/ldap/s_db-pass.age".publicKeys = allKeys;
  "auth/ldap/s_jwt-secret.age".publicKeys = allKeys;
  "auth/ldap/s_key-seed.age".publicKeys = allKeys;

  #
  # certs
  #
  "certs/ca.key.age".publicKeys = allKeys;
  "certs/ca.srl.age".publicKeys = allKeys;
  "certs/home.lan.csr.age".publicKeys = allKeys;
  "certs/home.lan.key.age".publicKeys = allKeys;

  #
  # containers
  #

  # archiver
  "containers/archiver/s_admin-pass.age".publicKeys = allKeys;
  "containers/archiver/s_auth-client.age".publicKeys = allKeys;
  "containers/archiver/s_db-pass.age".publicKeys = allKeys;

  # atuin
  "containers/atuin/s_db-pass.age".publicKeys = allKeys;

  # ebk
  "containers/ebk/s_auth-client.age".publicKeys = allKeys;
  "containers/ebk/s_db-pass.age".publicKeys = allKeys;
  "containers/ebk/s_secret-key.age".publicKeys = allKeys;

  # gluetun
  "containers/gluetun/s_api-key.age".publicKeys = allKeys;

  # gitea
  "containers/gitea/s_auth-client.age".publicKeys = allKeys;
  "containers/gitea/s_db-pass.age".publicKeys = allKeys;

  # grafana
  "containers/grafana/s_auth-client.age".publicKeys = allKeys;

  # immich
  "containers/immich/s_auth-client.age".publicKeys = allKeys;
  "containers/immich/s_db-pass.age".publicKeys = allKeys;

  # lidarr
  "containers/lidarr/s_api-key.age".publicKeys = allKeys;
  "containers/lidarr/s_db-pass.age".publicKeys = allKeys;

  # linkwarden
  "containers/link/s_auth-client.age".publicKeys = allKeys;
  "containers/link/s_db-pass.age".publicKeys = allKeys;
  "containers/link/s_meili-key.age".publicKeys = allKeys;
  "containers/link/s_next-auth.age".publicKeys = allKeys;

  # memos
  "containers/memos/s_auth-client.age".publicKeys = allKeys;
  "containers/memos/s_db-pass.age".publicKeys = allKeys;

  # opengist
  "containers/opengist/s_auth-client.age".publicKeys = allKeys;
  "containers/opengist/s_db-pass.age".publicKeys = allKeys;

  # papra
  "containers/papra/s_auth-client.age".publicKeys = allKeys;
  "containers/papra/s_auth-secret.age".publicKeys = allKeys;
  "containers/papra/s_storage-key.age".publicKeys = allKeys;
  "containers/papra/s_webhook-secret.age".publicKeys = allKeys;

  # slskd
  "containers/slskd/s_lidarr-api-key.age".publicKeys = allKeys;
  "containers/slskd/s_pass.age".publicKeys = allKeys;
  "containers/slskd/s_user.age".publicKeys = allKeys;
  "containers/slskd/s_webui-pass.age".publicKeys = allKeys;

  # trek
  "containers/trek/s_auth-client.age".publicKeys = allKeys;

  #
  # database
  #
  "db/s_pgadmin-pw.age".publicKeys = allKeys;
  "db/s_postgres-pw.age".publicKeys = allKeys;

  #
  # unsorted
  #
  "global-agenix.age".publicKeys = allKeys;
  "proton-key.age".publicKeys = allKeys;

  # tailscale
  "tailscale-api.age".publicKeys = allKeys;
  "tailscale-key.age".publicKeys = allKeys;
}
