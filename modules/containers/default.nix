/*
  modules/containers/default.nix

  part of der-home-server
  created 2026-04-19
*/

{
  inputs,
  outputs,
  config,
  pkgs,
  lib,
  globalConfig,
  ...
}:
let
  uid = toString globalConfig.squ.uid;
  gid = toString globalConfig.squ.gid;
in
{
  virtualisation = {
    quadlet.enable = true;
    podman.defaultNetwork.settings.dns_enabled = true;
    containers.storage.settings.storage = {
      driver = "overlay";
      options.overlay.mount_program = "${pkgs.fuse-overlayfs}/bin/fuse-overlayfs";
    };
  };

  age.secrets = {
    squ-config-key = {
      file = ../../secrets/s_global-agenix.age;
      owner = "squ";
      group = "squ";
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs outputs globalConfig;

      squConfigKeyPath = config.age.secrets.squ-config-key.path;
    };

    users.squ =
      {
        inputs,
        config,
        lib,
        globalConfig,
        userConfig,

        squConfigKeyPath,
        ...
      }:
      let
        baseDir = ".config/containers/systemd";
        mkPath = sub: "${config.home.homeDirectory}/${baseDir}/${sub}";
      in
      {
        imports = [
          inputs.quadlet-nix.homeManagerModules.quadlet
          inputs.agenix.homeManagerModules.age

          ./services/media

          ./services/atuin.nix
          ./services/ebk.nix
          ./services/gitea.nix
          ./services/immich.nix
          ./services/linkwarden.nix
          ./services/mail-archiver.nix
          ./services/memos.nix
          ./services/node-red.nix
          ./services/opengist.nix
          ./services/papra.nix
          ./services/qbittorrent.nix
          ./services/radicale.nix
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
          ./service-config.nix
          ./vpn.nix
        ];

        config = {
          age.identityPaths = [ squConfigKeyPath ];

          _module.args = {
            ports = globalConfig.ports;

            envSuffix = "${baseDir}/env";
            envSecretsSuffix = "${baseDir}/secrets";

            envPrefix = mkPath "env";
            envSecretsPrefix = mkPath "secrets";

            allServices = config.myServices;
            publicServices = lib.filterAttrs (name: value: value.serviceConfig != null) config.myServices;
          };

          # container volume mounts
          systemd.user.services."volume-provisioner" =
            let
              allVolumes = lib.flatten (
                lib.mapAttrsToList (
                  serviceName: serviceCfg: lib.attrValues serviceCfg.containerConfig.volumes
                ) config.myServices
              );

              uniqueVolumes = lib.unique allVolumes;

              provisionScript = pkgs.writeShellScript "provision-volumes" ''
                ${lib.concatMapStringsSep "\n" (path: ''
                  if [ ! -d "${path}" ]; then
                    echo "Creating volume directory: ${path}"
                    ${pkgs.coreutils}/bin/mkdir -p "${path}"
                  fi
                  echo "Setting permissions 755 on ${path}"
                  ${pkgs.coreutils}/bin/chmod 755 "${path}" || true
                '') uniqueVolumes}
              '';
            in
            {
              Unit = {
                Description = "Create and set permissions for container volumes";
                Before = [ "podman.service" ];
              };

              Service = {
                Type = "oneshot";
                ExecStart = provisionScript;
                RemainAfterExit = true;
              };

              Install = {
                WantedBy = [ "default.target" ];
              };
            };

          # files in home directory
          home.file = lib.mkMerge (
            lib.mapAttrsToList (
              serviceName: serviceCfg:
              lib.mapAttrs' (
                fileName: fileCfg:
                lib.nameValuePair (fileCfg.path) {
                  source = fileCfg.source;
                }
              ) serviceCfg.containerConfig.files
            ) config.myServices
          );

          systemd.user.services."podman-user-wait-network-online" = lib.mkForce {
            Unit.Description = "Replacement podman-user-wait-network-online to prevent quadlet hang";
            Service = {
              Type = "oneshot";
              ExecStart = "${pkgs.coreutils}/bin/true";
              RemainAfterExit = true;
            };
          };

          home.stateVersion = "25.11";
        };
      };
  };
}
