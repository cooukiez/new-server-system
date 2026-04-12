/*
  secrets/secrets.nix

  part of der-home-server
  created 2026-04-02
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
  # auth
  "auth/jwt-secret.age".publicKeys = allKeys;
  "auth/session.age".publicKeys = allKeys;
  "auth/storage-key.age".publicKeys = allKeys;
  "auth/oidc-hmac.age".publicKeys = allKeys;
  "auth/oidc-jwk.age".publicKeys = allKeys;
  "auth/mail-smtp.age".publicKeys = allKeys;

  # ldap
  "ldap/jwt-secret.age".publicKeys = allKeys;
  "ldap/key-seed.age".publicKeys = allKeys;
  "ldap/admin-pass.age".publicKeys = allKeys;

  # auth clients
  "auth/clients/grafana-oauth.age".publicKeys = allKeys;

  # general
  "global-agenix.age".publicKeys = allKeys;
  "gluetun-key.age".publicKeys = allKeys;
  "postgres-pw.age".publicKeys = allKeys;
  "tailscale-key.age".publicKeys = allKeys;

  # slskd
  "slskd/password.age".publicKeys = allKeys;
  "slskd/user.age".publicKeys = allKeys;
  "slskd/webui-pw.age".publicKeys = allKeys;
}
