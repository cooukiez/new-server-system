/*
  modules/nixos/services/default.nix

  part of der-home-server
  created 2026-04-02
*/

{
  config,
  pkgs,
  staticIP,
  ...
}:
{
  imports = [
    ./certificate.nix
    ./metrics.nix
    ./structure.nix
  ];

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "smbnix";
        "netbios name" = "smbnix";
        "security" = "user";

        "guest account" = "nobody";
        "map to guest" = "bad user";
      };

      "root-share" = {
        "path" = "/";
        "browseable" = "no";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "admin";
        "force user" = "root";
      };
    };
  };
}
