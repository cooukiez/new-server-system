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

  systemd.tmpfiles.rules = [
    "d /bak 0755 ${uid} ${gid} -"
    "d /data 0755 ${uid} ${gid} -"
    "d /media 0755 ${uid} ${gid} -"
    "d /opt 0755 ${uid} ${gid} -"
  ];

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

        ./services/business/ebk.nix
        ./services/business/mail-archiver.nix
        ./services/business/papra.nix
        ./services/business/radicale.nix

        ./services/atuin.nix
        ./services/crontab.nix
        ./services/gitea.nix
        ./services/immich.nix
        ./services/linkwarden.nix
        ./services/memos.nix
        ./services/node-red.nix
        ./services/opengist.nix
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
        images = import ../../generated-images.nix;

        ports = hostConfig.ports;

        envSuffix = "${baseDir}/env";
        envSecretsSuffix = "${baseDir}/secrets";

        envPrefix = mkPath "env";
        envSecretsPrefix = mkPath "secrets";

        allServices = config.myServices;
        publicServices = lib.filterAttrs (name: value: value.serviceConfig != null) config.myServices;

        documentsPath = "/data/documents";
        photosPath = "/media/photos";

        musicPath = "/media/music";
        downloadPath = "/media/download";
      };

      systemd.user.services."podman-volume-provisioning" = {
        Unit = {
          Before = [ "podman.service" ];
        };

        Install = {
          WantedBy = [ "default.target" ];
        };

        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = toString (
            pkgs.writeShellScript "provision-podman-volumes" ''
              ${
                let
                  allVolumes = config.virtualisation.quadlet.volumes or { };
                  mkDirCmds = pkgs.lib.mapAttrsToList (
                    name: vol:
                    if vol.volumeConfig ? device then
                      "${pkgs.coreutils}/bin/mkdir -p \"${vol.volumeConfig.device}\""
                    else
                      ""
                  ) allVolumes;
                  validCmds = builtins.filter (s: s != "") mkDirCmds;
                in
                pkgs.lib.concatStringsSep "\n" validCmds
              }
            ''
          );
        };
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
