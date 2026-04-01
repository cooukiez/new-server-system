/*
  flake.nix

  part of der-home-server
  created 2026-03-18
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

      # define user configuration
      users = import ./user-configuration.nix;

      # supported systems for flake packages, shell, etc.
      hostSystem = "x86_64-linux";
      systems = [
        hostSystem
      ];

      # set local subnet static IP
      staticIP = "192.168.100.98";

      dnsServers = [
        "1.1.1.1"
        "8.8.8.8"
        "9.9.9.9"
      ];

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
              users
              ;
            nixosModules = "${self}/modules/nixos";
          };
          modules = [
            # main config file
            ./configuration.nix

            inputs.agenix.nixosModules.default
            # inputs.hardware.nixosModules.lenovo-thinkpad-x1-yoga
          ];
        };

      mkHomeConfiguration =
        system: username: hostname:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            localSystem = {
              inherit system;
            };
          };

          extraSpecialArgs = {
            inherit
              inputs
              outputs
              hostSystem
              hostname
              staticIP
              ;
            userConfig = users.${username};
            nhModules = "${self}/modules/home";
          };
          modules = [
            ./home/${username}
          ];
        };
    in
    {
      # custom packages
      packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
      # formatter for your nix files
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

      # custom packages and modifications, exported as overlays
      overlays = {
        inherit (import ./overlays { inherit inputs; })
          additions
          modifications
          unstable-packages
          ;

        nur = inputs.nur.overlays.default;
      };

      # nixos system modules
      nixosModules = import ./modules/nixos;

      # home-manager modules
      homeManagerModules = import ./modules/home;

      # nixos configuration entrypoint
      nixosConfigurations = {
        dhs = mkNixosConfiguration "dhs";
      };

      # standalone home-manager configuration entrypoint
      homeConfigurations = {
        "admin@dhs" = mkHomeConfiguration hostSystem "admin" "dhs";
        "quadlet-user@dhs" = mkHomeConfiguration hostSystem "quadlet-user" "dhs";
      };
    };
}
