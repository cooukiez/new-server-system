/*
  flake.nix

  part of der-home-server
  created 2026-04-16
*/

{
  description = "system configuration for home server";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-system.url = "github:cooukiez/nixos-system";

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

      hostDirs = lib.attrNames (
        lib.filterAttrs (name: type: type == "directory") (builtins.readDir ./hosts)
      );

      mkHost =
        hostName:
        let
          hostPath = ./hosts/${hostName};
          hostConfig = import "${hostPath}/host.nix";
          userList = import ./users.nix;
        in
        lib.nixosSystem {
          system = hostConfig.hostSystem;
          specialArgs = {
            inherit
              inputs
              outputs
              hostConfig
              userList
              ;
            inherit (hostConfig) hostname;
          };

          modules = [
            hostPath

            ({ system.stateVersion = "25.11"; })
          ];
        };

      system = "x86_64-linux";
      supportedSystems = [ system ];

      forAllSystems = lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

      overlays = {
        inherit (import ./overlays { inherit inputs system; })
          additions
          modifications
          unstable-packages
          ;
      };

      containerModules = import ./modules/containers;
      serviceModules = import ./modules/services;

      nixosConfigurations = lib.genAttrs hostDirs (name: mkHost name);
    };
}
