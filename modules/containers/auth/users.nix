/*
  modules/containers/users.nix

  part of der-home-server
  created 2026-04-08
*/

{
  pkgs,
  ...
}:
let
  settingsFormat = pkgs.formats.yaml { };

  # groups = [ "admins" "users" ];

  autheliaUsers = {
    users = {
      admin = {
        disabled = false;
        displayname = "Admin";
        password = "$argon2id$v=19$m=16,t=2,p=1$YXV0aGVsaWFfYXV0aF9hZG1pbg$0FXF/+0nT3mVefVrXYfD6w";
        email = "management.homeserver@mailbox.org";
        name = "admin";
        groups = [ "admins" ];
      };
      ludwig = {
        disabled = false;
        displayname = "Ludwig";
        password = "$argon2id$v=19$m=16,t=2,p=1$YXV0aGVsaWFfYXV0aF9sdWR3aWc$CXk6qQgv6EZCD1T/Gfequg";
        email = "ludwig.geyer@mailbox.org";
        name = "ludwig";
        groups = [ "users" ];
      };
    };
  };
in
{
  home.file."containers/authelia/users.yml" = {
    source = settingsFormat.generate "authelia-users.yml" autheliaUsers;
  };
}
