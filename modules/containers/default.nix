/*
  modules/containers/default.nix

  part of der-home-server
  created 2026-04-08
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

  getNixFiles =
    dir:
    let
      contents = builtins.readDir dir;
    in
    map (name: dir + "/${name}") (
      builtins.filter (name: lib.hasSuffix ".nix" name) (builtins.attrNames contents)
    );
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

  systemd.tmpfiles.rules = [
    "Z /etc/certs 0400 ${uid} ${gid} -"

    "d /certs 0755 ${uid} ${gid} -"
    "Z /certs 0755 ${uid} ${gid} -"

    "d /opt 0755 ${uid} ${gid} -"
    "d /media 0755 ${uid} ${gid} -"
    "d /data 0755 ${uid} ${gid} -"

    "d /bak 0755 ${uid} ${gid} -"
    "d /bak/opt 0755 ${uid} ${gid} -"
  ];

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
        ]
        ++ (getNixFiles ./services)
        ++ [
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

        options.myServices = import ./service-config.nix { inherit config lib; };

        config = {
          age.identityPaths = [ squConfigKeyPath ];

          _module.args = {
            ports = globalConfig.ports;

            envSuffix = "${baseDir}/env";
            envSecretsSuffix = "${baseDir}/secrets";

            envPrefix = mkPath "env";
            envSecretsPrefix = mkPath "secrets";
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
                  ${pkgs.coreutils}/bin/chmod 755 "${path}"
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
          home.file = lib.concatMapAttrs (
            serviceName: serviceCfg:
            lib.mapAttrs' (
              fileName: fileCfg:
              lib.nameValuePair (fileCfg.path) {
                source = fileCfg.source;
              }

            ) serviceCfg.containerConfig.files
          ) config.myServices;

          # files in container directories
          systemd.user.services."file-provisioner" =
            let
              allFiles = lib.flatten (
                lib.mapAttrsToList (
                  serviceName: serviceCfg:
                  lib.mapAttrsToList (fileName: fileCfg: fileCfg) serviceCfg.containerConfig.files
                ) config.myServices
              );

              filesToCopy = lib.filter (f: f.copyToVolume != [ ]) allFiles;

              provisionScript = pkgs.writeShellScript "provision-container-files" ''
                ${lib.concatMapStringsSep "\n" (
                  file:
                  lib.concatMapStringsSep "\n" (dest: ''
                    echo "Provisioning ${file.name} to ${dest.volume}..."
                    ${pkgs.coreutils}/bin/cp -f "${file.fullPath}" "${dest.volume}"
                    ${pkgs.coreutils}/bin/chmod ${dest.mode} "${dest.volume}/${file.name}"
                  '') file.copyToVolume
                ) filesToCopy}
              '';

              # run every time
              timestamp = toString /.;
            in
            {
              Unit = {
                Description = "Provision configuration files to container volumes";
                Before = [ "podman.service" ];
              };

              Service = {
                Type = "oneshot";
                ExecStart = "${provisionScript}";
                RemainAfterExit = true;
              };

              Install = {
                WantedBy = [ "default.target" ];
              };
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

  # [get exec command]
  # podman inspect --format '{{.Config.Entrypoint}} {{.Config.Cmd}}' <container_name_or_id>

  # [find wrong permissions]
  # sudo find /opt/ -maxdepth 4 ! -user 10000 -o ! -group 10000
}
