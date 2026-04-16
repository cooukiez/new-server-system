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
let
  envSuffix = ".config/containers/systemd/env";
  envSecretsSuffix = ".config/containers/systemd/secrets";

  envPrefix = "${config.home.homeDirectory}/${envSuffix}";
  envSecretsPrefix = "${config.home.homeDirectory}/${envSecretsSuffix}";
in
{
  imports = [
    ./services/media

    ./services/ebk.nix
    ./services/gitea.nix
    ./services/immich.nix
    ./services/node-red.nix
    ./services/papra.nix
    ./services/qbittorrent.nix
    ./services/radicale.nix
    ./services/transfer-sh.nix
    ./services/vnstat.nix

    ./auth.nix
    ./database.nix
    ./dns.nix
    ./homepage.nix
    ./ldap.nix
    ./monitor.nix
    ./reverse-proxy.nix
    ./vpn.nix
  ];

  _module.args = {
    envSuffix = envSuffix;
    envSecretsSuffix = envSecretsSuffix;

    envPrefix = envPrefix;
    envSecretsPrefix = envSecretsPrefix;
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

  # get exec command
  # podman inspect --format '{{.Config.Entrypoint}} {{.Config.Cmd}}' <container_name_or_id>
}
