{
  pkgs,
  ...
}:
let
  del-baks = pkgs.writeShellScriptBin "del-baks" (builtins.readFile ./scripts/del-baks.sh);
in
{
  systemd.tmpfiles.rules = [
    "d /bak 0755 0 0 -"
    "d /bak/borg 0755 0 0 -"

    "d /bak/borg/config 0750 0 0 -"

    "d /bak/borg/data 0755 0 0 -"
    "d /bak/borg/cache 0755 0 0 -"

    "d /bak/opt 0750 0 0 -"
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

    preHook = ''
      umask 0022
    '';

    readWritePaths = [
      "/bak/opt"
      "/bak/borg"
    ];

    exclude = [
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
