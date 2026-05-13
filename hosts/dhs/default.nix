/*
hosts/dhs/default.nix

part of server system
created 2026-05-10
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
}: let
  squUid = toString hostConfig.squ.uid;
  squGid = toString hostConfig.squ.gid;
in {
  imports = [
    ./config.nix
    ./hardware-generated.nix
    ./hardware.nix

    inputs.nixos-system.systemModules.network
    inputs.nixos-system.systemModules.packages

    inputs.self.containerModules
    inputs.self.serviceModules

    inputs.agenix.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
    inputs.quadlet-nix.nixosModules.quadlet
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
      permittedInsecurePackages = [
        "ventoy-1.1.10"
      ];
    };
  };

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = "nix-command flakes";
      flake-registry = "";
      nix-path = config.nix.nixPath;
    };

    channel.enable = false;

    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;

    optimise.automatic = true;
    optimise.dates = ["03:45"];
  };

  age.identityPaths = ["/etc/ssh/ssh_host_ed25519_key"];

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
      })
      userList)
    // {
      squ = {
        description = "quadlet-user";
        uid = hostConfig.squ.uid;
        group = "squ";

        isNormalUser = true;
        createHome = true;

        extraGroups = ["keys"];

        linger = true;
        autoSubUidGidRange = true;
        shell = pkgs.zsh;
      };
    };

  users.groups.squ.gid = hostConfig.squ.gid;

  systemd.tmpfiles.rules =
    [
      "d /etc/certs 0755 ${squUid} ${squGid} -"
      "d /certs 0755 ${squUid} ${squGid} -"

      "C+ /etc/certs/ca.crt       0755 ${squUid} ${squGid} - ${../../certs/ca.crt}"
      "C+ /etc/certs/home.lan.crt 0755 ${squUid} ${squGid} - ${../../certs/home.lan.crt}"

      "C+ /certs/ca.crt           0755 ${squUid} ${squGid} - ${../../certs/ca.crt}"
      "C+ /certs/home.lan.crt     0755 ${squUid} ${squGid} - ${../../certs/home.lan.crt}"
    ]
    ++ lib.flatten (
      lib.mapAttrsToList (username: _: [
        "d /home/${username}/.ssh 0700 ${username} users - -"
      ])
      userList
    );

  age.secrets =
    lib.mapAttrs' (
      username: _:
        lib.nameValuePair "ssh-${username}" {
          file = ../../secrets/ssh/${username}.age;
          path = "/home/${username}/.ssh/id_ed25519";
          owner = username;
          group = "users";
        }
    )
    userList
    // {
      squ-config-key = {
        file = ../../secrets/global-agenix.age;
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

      squUid = squUid;
      squGid = squGid;

      squConfigKeyPath = config.age.secrets.squ-config-key.path;
    };

    users =
      (lib.mapAttrs (
          username: userConfig: {
            config,
            hostConfig,
            ...
          }: {
            imports = [
              inputs.agenix.homeManagerModules.default
            ];

            age.identityPaths = ["${config.home.homeDirectory}/.ssh/id_ed25519"];
            _module.args.userConfig = userConfig;

            home = {
              username = username;
              packages = userConfig.packages pkgs;

              homeDirectory = "/home/${username}";
              file.".ssh/id_ed25519.pub" = {
                text = ''
                  ${userConfig.sshPublicKey} ${username}@${hostConfig.hostname}
                '';
              };

              stateVersion = "25.11";
            };

            age.secrets.github-token.file = ../../secrets/github-token.age;

            programs.git = let
              gitSecretHelperScript = ''
                if [ "$1" = "get" ]; then
                  token=$(cat ${config.age.secrets.github-token.path})
                  echo "username=${userConfig.gitName}"
                  echo "password=$token"
                fi
              '';

              gitSecretHelper = pkgs.writeShellScript "git-secret-helper" gitSecretHelperScript;
            in {
              enable = true;

              settings = {
                user = {
                  name = userConfig.gitName;
                  email = userConfig.gitEmail;
                };

                credential.helper = "${gitSecretHelper}";
              };
            };

            programs.home-manager.enable = true;
            programs.zsh.enable = true;

            systemd.user.startServices = "sd-switch";
          }
        )
        userList)
      // {
        squ = {
          inputs,
          squConfigKeyPath,
          ...
        }: {
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
              permittedInsecurePackages = [];
            };
          };

          programs.zsh = {
            enable = true;
            shellAliases = {
              pg-admin = "podman exec -it postgres psql -U admin -d app_db";
              pg-init = "cat ~/containers/postgres/init-all-db.sql | podman exec -i postgres psql -U admin -d postgres";

              find-wrong-perms = "sudo find /opt/ -maxdepth 4 ! -user ${squUid} -o ! -group ${squGid}";
            };

            initContent = let
              mkPrompt = userColor: systemColor: let
                promptFirstColor = "%F{${userColor}}";
                promptSecondColor = "%F{${systemColor}}";
              in "${promptFirstColor}%n@${promptSecondColor}%m%f:%~$";
            in ''
              PROMPT='${mkPrompt "magenta" "yellow"} ';
            '';
          };

          age.identityPaths = [squConfigKeyPath];

          age.secrets = let
            mkCert = name: certName: {
              file = ../../secrets/certs/${name}.age;
              path = "/etc/certs/${certName}";
              mode = "444";
              symlink = false;
            };
          in {
            ca-key = mkCert "ca-key" "ca.key";
            ca-srl = mkCert "ca-srl" "ca.srl";
            home-lan-csr = mkCert "home-lan-csr" "home.lan.csr";
            home-lan-key = mkCert "home-lan-key" "home.lan.key";
          };

          systemd.user.startServices = "sd-switch";
          home.stateVersion = "25.11";
        };
      };
  };
}
