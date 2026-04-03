let
  settingsFormat = pkgs.formats.yaml { };

  autheliaUsers = {
    users = {
      admin = {
        disabled = false;
        displayname = "Admin";
        password = "$argon2id$v=19$m=65536,t=3,p=2$BpLnfgDsc2WD8F2q$o/vzA4myCqZZ36bUGsDY//8mKUYNZZaR0t4MFFSs+iM";
        email = "ludwig.geyer@mailbox.org";
        groups = [ "admins" ];
      };
      ludwig = {
        disabled = false;
        displayname = "Ludwig";
        password = "$argon2id$v=19$m=65536,t=3,p=2$BpLnfgDsc2WD8F2q$o/vzA4myCqZZ36bUGsDY//8mKUYNZZaR0t4MFFSs+iM";
        email = "ludwig.geyer@mailbox.org";
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