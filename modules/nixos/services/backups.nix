{
  pkgs,
  ...
}:
let
  del-baks = pkgs.writeShellScriptBin "del-baks" (builtins.readFile ./scripts/del-baks.sh);

  restricted = "0750 0 0";
  unrestricted = "0755 0 0";
in
{
  systemd.tmpfiles.rules = [
    "d /bak ${unrestricted} -"
    "d /bak/borg ${unrestricted} -"

    "d /bak/borg/config ${restricted} -"

    "d /bak/borg/data ${unrestricted} -"
    "d /bak/borg/cache ${unrestricted} -"

    "d /bak/opt ${restricted} -"
  ];

  environment.systemPackages = with pkgs; [
    del-baks
  ];

  services.borgbackup.jobs."opt-backup" = {
    paths = [ "/opt" ];
    repo = "/bak/opt";
    doInit = true;
    encryption.mode = "none";

    user = "root";

    environment = {
      BORG_BASE_DIR = "/bak/borg";
      BORG_CONFIG_DIR = "/bak/borg/config";
      BORG_DATA_DIR = "/bak/borg/data";
      BORG_CACHE_DIR = "/bak/borg/cache";
    };

    failOnWarnings = false;

    preHook = ''
      umask 0022
    '';

    postHook = ''
      echo "Setting permissions on data and cache."
      chmod -R 755 /bak/borg/data /bak/borg/cache
    '';

    readWritePaths = [
      "/bak/opt"
      "/bak/borg"
    ];

    exclude = [
      "/opt/postgres/data"
      "/opt/lidarr/data/MediaCover"
    ];

    startAt = "daily";
    prune.keep = {
      # all backups from last day
      within = "1d";

      # keep the last 7 daily backups
      daily = 7;
      # keep the last 4 weekly backups
      weekly = 4;
      # keep the last 3 monthly backups
      monthly = 3;
    };
  };
}
