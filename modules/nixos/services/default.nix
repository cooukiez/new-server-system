/*
  modules/nixos/services/default.nix

  part of der-home-server
  created 2026-04-02
*/

{
  config,
  pkgs,
  globalConfig,
  ...
}:
{
  imports = [
    ./backups.nix
    ./certificate.nix
    ./metrics.nix
    ./structure.nix
  ];

  services.vnstat.enable = true;

  services.glances = {
    enable = true;

    extraArgs = [
      "-w"
      "-p"
      "${toString globalConfig.ports.glances}"
      "-B"
      "0.0.0.0"
    ];
  };

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
