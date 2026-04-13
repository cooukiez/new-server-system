/*
  modules/containers/default.nix

  part of der-home-server
  created 2026-04-08
*/

{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./services/media
    ./services/gitea.nix
    ./services/immich.nix
    ./services/qbittorrent.nix
    ./services/transfer-sh.nix
    ./services/vnstat.nix

    ./auth.nix
    ./database.nix
    ./dns.nix
    ./ldap.nix
    ./monitor.nix
    ./reverse-proxy.nix
    ./vpn.nix
  ];

  _module.args = {
    envPrefix = "${config.xdg.configHome}/containers/systemd/env";
    envSecretsPrefix = "${config.xdg.configHome}/containers/systemd/secrets";
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      networks = {
        internal.networkConfig.subnets = [ "10.1.1.1/24" ];
      };
    };

  systemd.user.services."podman-user-wait-network-online" = lib.mkForce {
    Unit.Description = "Dummy podman-user-wait-network-online to prevent quadlet hang";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/true";
      RemainAfterExit = true;
    };
  };
}
