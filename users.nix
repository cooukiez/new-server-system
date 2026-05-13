/*
users.nix

part of server system
created 2026-04-02
*/
{
  admin = {
    email = "";
    fullName = "Admin";

    gitName = "cooukiez";
    gitEmail = "ludwig-geyer@web.de";

    name = "admin";

    sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGqloF2EAQJl6bwdOBhMXvkund47pwRzIQC8KMaiBEbK";

    packages = pkgs: with pkgs; [];
  };
}
