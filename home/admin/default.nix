/*
  home/admin/default.nix

  part of der-home-server
  created 2026-04-16
*/

{
  inputs,
  outputs,
  config,
  globalConfig,
  ...
}:
{

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    extraSpecialArgs = {
      inherit inputs outputs globalConfig;
      userConfig = globalConfig.users.admin;
    };

    users.admin =
      {
        inputs,
        config,
        globalConfig,
        userConfig,
        ...
      }:
      {
        imports = [
          inputs.self.homeManagerModules.programs
        ];

        home = {
          username = "${userConfig.name}";
          homeDirectory = "/home/${userConfig.name}";
          sessionVariables = {

          };
        };

        programs.home-manager.enable = true;
        systemd.user.startServices = "sd-switch";

        home.stateVersion = "25.11";
      };
  };
}
