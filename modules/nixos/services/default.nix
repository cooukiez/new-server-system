/*
  modules/nixos/services/default.nix

  part of der-home-server
  created 2026-03-19
*/

{
  config,
  pkgs,
  staticIP,
  ...
}:
{
  imports = [
    ./tmpfiles.nix
  ];

  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  services.fwupd.enable = true;
  services.vnstat.enable = true;

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      UseDns = true;
      X11Forwarding = false;

      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";

    extraUpFlags = [
      "--advertise-exit-node"
    ];
  };
}
