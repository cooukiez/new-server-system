/*
  home/admin/default.nix

  part of der-home-server
  created 2026-04-02
*/

{
  inputs,
  config,
  userConfig,
  ...
}:
{

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
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

    users.admin =
      {
        inputs,
        config,
        userConfig,
        ...
      }:
      {
        imports = [
          inputs.self.homeManagerModules.programs
          inputs.nixvim.homeModules.default
        ];

        nixpkgs = {
          overlays = [
            inputs.self.overlays.additions
            inputs.self.overlays.modifications
            inputs.self.overlays.unstable-packages
            inputs.self.overlays.nur
          ];

          # configure nixpkgs instance
          config = {
            # allow unfree packages
            allowUnfree = true;
            permittedInsecurePackages = [
              "dotnet-sdk-6.0.428"
              "dotnet-runtime-6.0.36"
            ];
          };
        };

        home = {
          username = "${userConfig.name}";
          homeDirectory = "/home/${userConfig.name}";
          sessionVariables = {

          };
        };

        programs.home-manager.enable = true;
        systemd.user.startServices = "sd-switch";

        # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
        home.stateVersion = "25.11";
      };
  };
}
