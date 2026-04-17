{
  services.borgbackup.jobs."opt-backup" = {
    paths = [ "/opt" ];
    repo = "/bak/opt";
    doInit = true;
    encryption.mode = "none";

    user = "root";

    exclude = [
      "/opt/jellyfin/cache"
      "/opt/lidarr/cache"
      "/opt/lidarr/MediaCover"
    ];

    startAt = "daily";
    prune.keep = {
      within = "1d"; # all backups from last day
      daily = 7; # keep the last 7 daily backups
      weekly = 4; # keep the last 4 weekly backups
      monthly = 3; # keep the last 3 monthly backups
    };

    readWritePaths = [ "/bak/opt" ];
  };
}
