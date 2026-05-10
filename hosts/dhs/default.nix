/*
  hosts/lvl/default.nix

  created by ludw
  on 2026-04-22
*/

{
  inputs,
  outputs,
  config,
  pkgs,
  lib,
  hostConfig,
  userList,
  ...
}:
{
  imports = [
    ./config.nix
    ./hardware-generated.nix
    ./hardware.nix

    inputs.nixos-system.systemModules.network
    inputs.nixos-system.systemModules.packages

    inputs.agenix.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
  ];

  nixpkgs = {
    overlays = [
      inputs.self.overlays.additions
      inputs.self.overlays.modifications
      inputs.self.overlays.unstable-packages

      (final: prev: {
        valkey = prev.valkey.overrideAttrs (oldAttrs: {
          doCheck = false;
        });
      })
    ];

    config = {
      allowUnfree = true;
      permittedInsecurePackages = [ ];
    };
  };

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        experimental-features = "nix-command flakes";
        flake-registry = "";
        nix-path = config.nix.nixPath;
      };

      channel.enable = false;

      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;

      optimise.automatic = true;
      optimise.dates = [ "03:45" ];
    };

  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  users.users =
    (lib.mapAttrs (_: user: {
      description = user.fullName;
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "tailscale"

        "cdrom"
        "optical"
      ];
      password = "CHANGE-ME";
      shell = pkgs.zsh;
    }) userList)
    // {
      squ = {
        description = "quadlet-user";
        uid = hostConfig.squ.uid;
        group = "squ";

        isNormalUser = true;
        createHome = true;

        linger = true;
        autoSubUidGidRange = true;
        shell = pkgs.zsh;
      };
    };

  users.groups.squ.gid = hostConfig.squ.gid;

  systemd.tmpfiles.rules = [
    "Z /etc/certs 0400 ${hostConfig.squ.uid} ${hostConfig.squ.gid} -"
  ]
  ++ lib.flatten (
    lib.mapAttrsToList (username: _: [
      "d /home/${username}/.ssh 0700 ${username} users - -"
    ]) userList
  );

  /*
    age.secrets = lib.mapAttrs' (
      username: _:
      lib.nameValuePair "ssh-${username}" {
        file = ../../secrets/ssh/${username}.age;
        path = "/home/${username}/.ssh/id_ed25519";
        owner = username;
        group = "users";
        mode = "600";
      }
    ) userList;
  */

  age.secrets = {
    squ-config-key = {
      file = ../../secrets/s_global-agenix.age;
      owner = "squ";
      group = "squ";
    };
  };

  home-manager = {
    useGlobalPkgs = false;
    useUserPackages = true;
    backupFileExtension = "hm-bak";

    extraSpecialArgs = {
      inherit
        inputs
        outputs
        hostConfig
        ;

      squConfigKeyPath = config.age.secrets.squ-config-key.path;
    };

    users.squ =
      {
        inputs,
        squConfigKeyPath,
        ...
      }:
      {
        imports = [
          inputs.quadlet-nix.homeManagerModules.quadlet
          inputs.agenix.homeManagerModules.default
        ];

        nixpkgs = {
          overlays = [
            inputs.self.overlays.additions
            inputs.self.overlays.modifications
            inputs.self.overlays.unstable-packages

            (final: prev: {
              valkey = prev.valkey.overrideAttrs (oldAttrs: {
                doCheck = false;
              });
            })
          ];

          config = {
            allowUnfree = true;
            permittedInsecurePackages = [ ];
          };
        };

        age.identityPaths = [ squConfigKeyPath ];

        systemd.user.startServices = "sd-switch";
        home.stateVersion = "25.11";
      };
  };
}
