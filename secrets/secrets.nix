/*
  secrets/secrets.nix

  part of der-home-server
  created 2026-03-24
*/

let
  # laptop keys
  ceirsLaptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDTfSJByS/+4vIn4AMZMjy2ehWfHFDnSq2WXzMDZnXDk ceirs@lvl";
  ludwLaptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGHBIf2ycXKqaa5o8isf99gRFRhtvefyjq1ib/x0lF9e ludw@lvl";
  rediLapotp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGe437tVoIrqmV1UzVBObyvsr+pNJ6Gp+UgQtWx6frpV redi@lvl";

  rootLaptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOe6C64fZmVmZN1uQSJexFBoQRFaQXOpfg9piE+r8cdQ";

  # server keys
  adminUser = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDGteDPPpAVNuYBA06UnbawTDhNEek83a8sALWWuGnQZ admin@dhs";
  dhsServer = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIESWux3pGlD3wCWU+UHFut7rJn6T8DCL4L6ccHz8uRDY root@dhs";

  oldKeys = [
    adminUser
    dhsServer
  ];

  newAllKeys = [
    ceirsLaptop
    ludwLaptop
    rediLapotp

    rootLaptop

    adminUser
    dhsServer
  ];
in
{
  "maxmind-license.age".publicKeys = oldKeys;

  "gluetun-wg-key.age".publicKeys = newAllKeys;

  "slsk-user.age".publicKeys = newAllKeys;
  "slsk-pass.age".publicKeys = newAllKeys;
  "slsk-webui-pass.age".publicKeys = newAllKeys;
}
