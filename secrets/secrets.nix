/*
  secrets/secrets.nix

  part of der-home-server
  created 2026-04-20
*/

let
  # laptop keys
  ceirsLaptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDTfSJByS/+4vIn4AMZMjy2ehWfHFDnSq2WXzMDZnXDk ceirs@lvl";
  ludwLaptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGHBIf2ycXKqaa5o8isf99gRFRhtvefyjq1ib/x0lF9e ludw@lvl";
  rediLapotp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGe437tVoIrqmV1UzVBObyvsr+pNJ6Gp+UgQtWx6frpV redi@lvl";

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
    ceirsLaptop
    ludwLaptop
    rediLapotp

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

  # auth
  "auth/s_jwt-secret.age".publicKeys = allKeys;
  "auth/s_mail-smtp.age".publicKeys = allKeys;
  "auth/s_oidc-hmac.age".publicKeys = allKeys;
  "auth/s_oidc-jwk.age".publicKeys = allKeys;
  "auth/s_session.age".publicKeys = allKeys;
  "auth/s_storage-key.age".publicKeys = allKeys;

  # auth clients
  "auth/clients/s_ebk.age".publicKeys = allKeys;
  "auth/clients/s_grafana.age".publicKeys = allKeys;
  "auth/clients/e_link.age".publicKeys = allKeys;
  "auth/clients/e_mail-archiver.age".publicKeys = allKeys;
  "auth/clients/e_opengist.age".publicKeys = allKeys;
  "auth/clients/s_papra.age".publicKeys = allKeys;
  "auth/clients/e_trek.age".publicKeys = allKeys;

  # ebk
  "ebk/s_secret-key.age".publicKeys = allKeys;

  # homepage

  # archiver
  /*
    "archiver/e_meili-key.age".publicKeys = allKeys;
    "archiver/e_encrypt-key.age".publicKeys = allKeys;
    "archiver/e_jwt-secret.age".publicKeys = allKeys;
  */
  "archiver/e_admin-pass.age".publicKeys = allKeys;

  # ldap
  "ldap/s_admin-pass.age".publicKeys = allKeys;
  "ldap/s_jwt-secret.age".publicKeys = allKeys;
  "ldap/s_key-seed.age".publicKeys = allKeys;

  # linkwarden
  "link/e_meili-key.age".publicKeys = allKeys;
  "link/e_link-meili-key.age".publicKeys = allKeys;
  "link/e_next-auth.age".publicKeys = allKeys;

  # papra
  "papra/e_auth-secret.age".publicKeys = allKeys;
  "papra/e_storage-key.age".publicKeys = allKeys;
  "papra/e_webhook-secret.age".publicKeys = allKeys;

  # slskd
  "slskd/e_pass.age".publicKeys = allKeys;
  "slskd/e_user.age".publicKeys = allKeys;
  "slskd/e_webui-pw.age".publicKeys = allKeys;

  #
  # unsorted
  #

  # certs
  "certs/ca.key.age".publicKeys = allKeys;
  "certs/ca.srl.age".publicKeys = allKeys;
  "certs/home.lan.csr.age".publicKeys = allKeys;
  "certs/home.lan.key.age".publicKeys = allKeys;

  # general
  "s_global-agenix.age".publicKeys = allKeys;
  "s_gluetun-key.age".publicKeys = allKeys;

  # database
  "s_pgadmin-pw.age".publicKeys = allKeys;
  "s_postgres-pw.age".publicKeys = allKeys;

  # tailscale
  "s_tailscale-api.age".publicKeys = allKeys;
  "s_tailscale-key.age".publicKeys = allKeys;
}
