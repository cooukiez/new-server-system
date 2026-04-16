/*
  flake.nix

  part of der-home-server
  created 2026-04-12
*/

# der-home-server configuration

{
  description = "system configuration for home server";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix.url = "github:ryantm/agenix";
    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib;

      globalConfig = {
        dnsServers = [
          "1.1.1.1"
          "8.8.8.8"
          "9.9.9.9"
        ];

        hostname = "dhs";
        hostSystem = "x86_64-linux";
        staticIP = "192.168.178.3";

        squIds = {
          uid = 10000;
          gid = 10000;
        };

        ports = import ./port-configuration.nix;
        users = import ./user-configuration.nix;
      };

      systems = [ globalConfig.hostSystem ];
      forAllSystems = lib.genAttrs systems;

      mkUsers =
        pkgs:
        (lib.mapAttrs (_: user: {
          description = user.fullName;
          password = "CHANGE-ME";

          isNormalUser = true;
          createHome = true;

          extraGroups = [
            "wheel"
            "networkmanager"
          ];
          shell = pkgs.zsh;
        }) globalConfig.users)
        // {
          squ = {
            description = "quadlet-user";
            uid = globalConfig.squIds.uid;
            group = "squ";

            isNormalUser = true;
            createHome = true;

            linger = true;
            autoSubUidGidRange = true;
          };
        };

      mkNixos =
        hostname:
        lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs globalConfig;
            nixosModules = "${self}/modules/nixos";
          };

          modules = [
            outputs.nixosModules.common
            outputs.nixosModules.core
            outputs.nixosModules.services
            outputs.containerModules

            inputs.home-manager.nixosModules.home-manager
            inputs.quadlet-nix.nixosModules.quadlet
            inputs.agenix.nixosModules.default

            outputs.homeConfigurations.admin

            (
              { pkgs, ... }:
              {
                nixpkgs = {
                  overlays = [
                    inputs.self.overlays.additions
                    inputs.self.overlays.modifications
                    inputs.self.overlays.unstable-packages
                  ];

                  config.allowUnfree = true;
                  config.permittedInsecurePackages = [ ];
                };

                nix =
                  let
                    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
                    myNixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
                  in
                  {
                    settings = {
                      experimental-features = "nix-command flakes";
                      flake-registry = "";
                      nix-path = myNixPath;
                    };

                    registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
                    nixPath = myNixPath;

                    channel.enable = false;
                    optimise.automatic = true;
                    optimise.dates = [ "03:45" ];
                  };

                users.users = mkUsers pkgs;
                users.groups.squ.gid = globalConfig.squIds.gid;

                system.stateVersion = "25.11";
              }
            )
          ];
        };
    in
    {
      packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
      overlays = {
        inherit (import ./overlays { inherit inputs; })
          additions
          modifications
          unstable-packages
          ;
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home;
      containerModules = import ./modules/containers;

      homeConfigurations = import ./home;

      nixosConfigurations = {
        dhs = mkNixos "dhs";
      };
    };
}
