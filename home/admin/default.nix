/*
  home/admin/default.nix

  part of der-home-server
  created 2026-03-18
*/

# configure home environment

{
  inputs,
  config,
  userConfig,
  ...
}:
{
  # import home-manager modules here
  imports = [
    inputs.self.homeManagerModules.programs

    inputs.nixvim.homeModules.default
  ];
  nixpkgs = {
    # add overlays here
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

  # enable home-manager
  programs.home-manager.enable = true;

  # nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.11";
}
