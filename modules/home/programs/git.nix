/*
  modules/home/programs/git.nix

  part of der-home-server
  created 2026-03-18
*/

{
  programs.git = {
    enable = true;
    lfs.enable = true;

    settings = {
      user = {
        name = "home-server";
        email = "ludwig-geyer@web.de";
      };

      advice.defaultBranchName = false;

      safe = {
        directory = [
          "/etc/nixos"
        ];
      };
    };
  };
}
