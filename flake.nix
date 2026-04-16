/*
  flake.nix

  part of der-home-server
  created 2026-04-12
*/

# der-home-server configuration

# start config from https://github.com/Misterio77/nix-starter-configs
# inspired by https://github.com/AlexNabokikh/nix-config

{
  description = "system configuration for home server";

  inputs = {
    # nixpkgs stable nixpkgs-unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # nixos profiles to optimize settings for different hardware
    hardware.url = "github:nixos/nixos-hardware";

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # home-manager / nixos vim config with nixvim
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
    agenix.url = "github:ryantm/agenix";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      hostSystem = "x86_64-linux";
      systems = [
        hostSystem
      ];

      staticIP = "192.168.178.3";
      dnsServers = [
        "1.1.1.1"
        "8.8.8.8"
        "9.9.9.9"
      ];

      users = import ./user-configuration.nix;
      ports = import ./port-configuration.nix;

      squUID = 10000;
      squGID = 10000;

      forAllSystems = nixpkgs.lib.genAttrs systems;

      mkNixosConfiguration =
        hostname:
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit
              inputs
              outputs
              hostSystem
              hostname
              staticIP
              dnsServers
              ports
              squUID
              squGID
              users
              ;
            nixosModules = "${self}/modules/nixos";
          };

          modules = [
            inputs.self.nixosModules.common
            inputs.self.nixosModules.services

            # admin configuration
            inputs.self.homeConfigurations.admin

            # container configuration
            inputs.self.containerModules

            ./configuration.nix

            inputs.home-manager.nixosModules.home-manager
            inputs.quadlet-nix.nixosModules.quadlet
            inputs.agenix.nixosModules.default
          ];
        };
    in
    {
      packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

      overlays = {
        inherit (import ./overlays { inherit inputs; })
          additions
          modifications
          unstable-packages
          ;

        nur = inputs.nur.overlays.default;
      };

      homeConfigurations = import ./home;

      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home;

      containerModules = import ./modules/containers;

      # nixos configuration entrypoint
      nixosConfigurations = {
        dhs = mkNixosConfiguration "dhs";
      };
    };
}
