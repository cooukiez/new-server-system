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
          inputs.agenix.homeManagerModules.default

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

        age.identityPaths = [ squConfigKeyPath ];

        _module.args = {
          ports = globalConfig.ports;

          envSuffix = "${baseDir}/env";
          envSecretsSuffix = "${baseDir}/secrets";

          envPrefix = mkPath "env";
          envSecretsPrefix = mkPath "secrets";
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

        home.stateVersion = "25.11";
      };
  };

  # [get exec command]
  # podman inspect --format '{{.Config.Entrypoint}} {{.Config.Cmd}}' <container_name_or_id>

  # [find wrong permissions]
  # sudo find /opt/ -maxdepth 4 ! -user 10000 -o ! -group 10000
}
