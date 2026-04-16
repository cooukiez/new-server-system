/*
  modules/containers/default.nix

  part of der-home-server
  created 2026-04-08
*/

{
  inputs,
  config,
  pkgs,
  staticIP,
  ports,
  ...
}:
{
  virtualisation.quadlet.enable = true;
  virtualisation.podman.defaultNetwork.settings.dns_enabled = true;
  virtualisation.containers.storage.settings = {
    storage = {
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
      inherit
        inputs
        outputs
        globalConfig
        ;

      squConfigKeyPath = config.age.secrets.squ-config-key.path;
    };

    users.squ =
      {
        inputs,
        config,
        globalConfig,
        userConfig,

        squConfigKeyPath,
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
          inputs.quadlet-nix.homeManagerModules.quadlet
          inputs.agenix.homeManagerModules.default
          inputs.sops-nix.homeManagerModules.sops

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

        age.identityPaths = [ squConfigKeyPath ];
        sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

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

        home.stateVersion = "25.11";
      };
  };

  # [get exec command]
  # podman inspect --format '{{.Config.Entrypoint}} {{.Config.Cmd}}' <container_name_or_id>

  # [find wrong permissions]
  # sudo find /opt/ -maxdepth 4 ! -user 10000 -o ! -group 10000
}
