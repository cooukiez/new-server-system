/*
  modules/nixos/services/default.nix

  part of der-home-server
  created 2026-04-16
*/

{
  config,
  pkgs,
  globalConfig,
  ...
}:
{
  imports = [
    ./certificate.nix
    ./metrics.nix
    ./structure.nix
  ];

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      UseDns = true;
      X11Forwarding = false;

      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
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
}
