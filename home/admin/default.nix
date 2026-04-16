/*
  home/admin/default.nix

  part of der-home-server
  created 2026-04-02
*/

{
  inputs,
  outputs,
  config,
  hostSystem,
  hostname,
  staticIP,
  userConfig,
  users,
  ...
}:
{

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    extraSpecialArgs = {
      inherit
        inputs
        outputs
        hostSystem
        hostname
        staticIP
        ;

      userConfig = users.admin;
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
