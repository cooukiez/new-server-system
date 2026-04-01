/*
  disko-config.nix

  part of der-home-server
  created 2026-04-01
*/

{
  lib,
  ...
}:
{
  disko.devices = {
    disk = {
      dhs-disk = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };

            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
    };

    zpool = {
      zroot = {
        type = "zpool";
        rootFsOptions = {
          acltype = "posixacl";
          relatime = "on";
          canmount = "off";
          xattr = "sa";
          compression = "zstd";
          dnodesize = "auto";
          normalization = "formD";
          "com.sun:auto-snapshot" = "false";
        };

        options = {
          ashift = "12";
        };

        datasets = {
          local = {
            type = "zfs_fs";
            options.canmount = "off";
          };

          "local/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "legacy";
            options."com.sun:auto-snapshot" = "false";
          };

          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options.mountpoint = "legacy";
            options.atime = "off";
            options.canmount = "on";
          };

          "local/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options.mountpoint = "legacy";
            options."com.sun:auto-snapshot" = "false";
          };

          "local/var" = {
            type = "zfs_fs";
            mountpoint = "/var";
            options.mountpoint = "legacy";
            options."com.sun:auto-snapshot" = "false";
          };

          "local/opt" = {
            type = "zfs_fs";
            mountpoint = "/opt";
            options.mountpoint = "legacy";
            options."com.sun:auto-snapshot" = "false";
          };

          "local/media" = {
            type = "zfs_fs";
            mountpoint = "/media";
            options.mountpoint = "legacy";
            options."com.sun:auto-snapshot" = "false";
          };

          "swap" = {
            type = "zfs_unmanaged";
            content = {
              type = "zfs_volume";
              size = "16G";
              content = {
                type = "swap";
              };
            };
          };

          reserved = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              reservation = "5G";
            };
          };
        };
      };
    };
  };
}
