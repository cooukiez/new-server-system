/*
  modules/nixos/services/default.nix

  part of der-home-server
  created 2026-04-16
*/

{
  config,
  pkgs,
  globalConfig,
  ...
}:
let
  papraMaintenanceScript = pkgs.writeShellScript "papra-db-update" ''
    set -e
    SYSTEMCTL="${pkgs.systemd}/bin/systemctl"
    SQLITE="${pkgs.sqlite}/bin/sqlite3"
    DB_PATH="/opt/papra/data/db/db.sqlite"

    echo "Stopping papra service for user squ..."
    $SYSTEMCTL --user -M squ@.host stop papra.service

    echo "Running database update..."
    $SQLITE "$DB_PATH" "UPDATE documents SET original_name = 'none';"

    echo "Starting papra service for user squ..."
    $SYSTEMCTL --user -M squ@.host start papra.service

    echo "Maintenance complete."
  '';
in
{
  imports = [
    ./certificate.nix
    ./metrics.nix
    ./structure.nix
  ];

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      UseDns = true;
      X11Forwarding = false;

      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "smbnix";
        "netbios name" = "smbnix";
        "security" = "user";

        "guest account" = "nobody";
        "map to guest" = "bad user";
      };

      "root-share" = {
        "path" = "/";
        "browseable" = "no";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "admin";
        "force user" = "root";
      };
    };
  };

  services.glances = {
    enable = true;

    extraArgs = [
      "-w"
      "-p"
      "${toString globalConfig.ports.glances}"
      "-B"
      "0.0.0.0"
    ];
  };

  # papra maintenance configuration
  systemd.services.papra-db-maintenance = {
    description = "Stop Papra, update SQLite DB, and restart";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${papraMaintenanceScript}";
      User = "root";
    };
  };

  # papra maintenance timer
  systemd.timers.papra-db-maintenance = {
    description = "Run Papra DB maintenance daily at 3am";
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      Persistent = true;
      Unit = "papra-db-maintenance.service";
    };
    wantedBy = [ "timers.target" ];
  };
}
