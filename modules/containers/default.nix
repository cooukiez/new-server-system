/*
  modules/containers/default.nix

  part of der-home-server
  created 2026-04-19
*/

{
  hostConfig,
  ...
}:
let
  uid = toString hostConfig.squ.uid;
  gid = toString hostConfig.squ.gid;
in
{
  home-manager.users.squ =
    {
      config,
      pkgs,
      lib,
      hostConfig,
      ...
    }:
    let
      baseDir = ".config/containers/systemd";
      mkPath = sub: "${config.home.homeDirectory}/${baseDir}/${sub}";
    in
    {
      imports = [
        ../service-config.nix

        ./services/media

        ./services/org/ebk.nix
        ./services/org/mail-archiver.nix
        ./services/org/radicale.nix

        ./services/atuin.nix
        ./services/crontab.nix
        ./services/gitea.nix
        ./services/immich.nix
        ./services/linkwarden.nix
        ./services/memos.nix
        ./services/node-red.nix
        ./services/opengist.nix
        ./services/papra.nix
        ./services/stirling.nix
        ./services/transfer-sh.nix
        ./services/trek.nix
        ./services/vnstat.nix

        ./auth.nix
        ./backup.nix
        ./database.nix
        ./dns.nix
        ./homepage.nix
        ./ldap.nix
        ./monitor.nix
        ./reverse-proxy.nix
        ./vpn.nix
      ];

      _module.args = {
        ports = hostConfig.ports;

        envSuffix = "${baseDir}/env";
        envSecretsSuffix = "${baseDir}/secrets";

        envPrefix = mkPath "env";
        envSecretsPrefix = mkPath "secrets";

        allServices = config.myServices;
        publicServices = lib.filterAttrs (name: value: value.serviceConfig != null) config.myServices;
      };

      systemd.user.services."podman-user-wait-network-online" = lib.mkForce {
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.coreutils}/bin/true";
          RemainAfterExit = true;
        };
      };
    };
}
