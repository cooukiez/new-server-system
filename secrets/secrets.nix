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
  squUser = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICJUMtqXM+M2NPPa1/BvATAn40e3nZRh2RzHc/BkSqeN squ@dhs";
  adminUser = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGqloF2EAQJl6bwdOBhMXvkund47pwRzIQC8KMaiBEbK admin@dhs";
  dhsServer = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID7ao1FUxiK3WeHSeVsxlrIMWlFJVsHndjadOxzP4taE root@dhs";

  serverKeys = [
    squUser
    adminUser
    dhsServer
  ];

  allKeys = [
    ceirsLaptop
    ludwLaptop
    rediLapotp

    rootLaptop

    squUser
    adminUser
    dhsServer
  ];
in
{
  "auth-jwt.age".publicKeys = allKeys;
  "auth-session.age".publicKeys = allKeys;
  "auth-storage-key.age".publicKeys = allKeys;

  "auth-oidc-hmac.age".publicKeys = allKeys;
  "auth-immich-secret.age".publicKeys = allKeys;

  "auth-cert.age".publicKeys = allKeys;
  "auth-key.age".publicKeys = allKeys;
  "auth-ec-cert.age".publicKeys = allKeys;
  "auth-ec-key.age".publicKeys = allKeys;

  "postgres-pw.age".publicKeys = allKeys;
}
