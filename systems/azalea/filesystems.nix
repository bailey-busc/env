{
  lib,
  config,
  self,
  ...
}:
let
  inherit (builtins) toString;
  inherit (lib)
    mkIf
    genAttrs
    flip
    ;
  inherit (self.lib) mergeAttrs' mapAttrNames';

  device = throw "Set me";

  # Sizes
  rootSizeGb = throw "Set me";
  tmpSizeGb = throw "Set me";
  swapSizeGb = throw "Set me";
  bootSizeGb = throw "Set me";

  # ZFS
  rootPoolName = throw "Set me";
  rootDatasetName = throw "Set me";
  userDatasetName = throw "Set me";
in
{
  disko.devices = {
    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [
          "defaults"
          "size=${toString rootSizeGb}G"
          "mode=755"
        ];
      };
      "/tmp" = {
        fsType = "tmpfs";
        mountOptions = [
          "defaults"
          "size=${toString tmpSizeGb}G"
          "mode=755"
        ];
      };
    };
    disk = {
      primary = {
        inherit device;
        type = "disk";

        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "${toString bootSizeGb}G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "nofail"
                  "umask=0077"
                  "iocharset=iso8859-1"
                  "X-mount.mkdir"
                ];
              };
            };
            swap = {
              size = "${toString swapSizeGb}G";
              content = {
                type = "swap";
                randomEncryption = true;
                resumeDevice = true;
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "luks";
                name = "luks-${rootPoolName}";
                settings = {
                  crypttabExtraOpts = [ "tpm2-device=auto" ];
                  bypassWorkqueues = true;
                  allowDiscards = true;
                };
                content = {
                  type = "zfs";
                  pool = rootPoolName;
                };
              };
            };
          };
        };
      };
    };
    zpool."${rootPoolName}" = {
      type = "zpool";
      options = {
        ashift = "12";
        autotrim = "on";
      };
      rootFsOptions = {
        compression = "zstd";
        acltype = "posixacl";
        canmount = "off";
        normalization = "formD";
        relatime = "on";
        dnodesize = "auto";
        xattr = "sa";
        mountpoint = "none";
        "com.sun:auto-snapshot" = "false";
      };

      datasets =
        let
          container = genAttrs [ rootDatasetName userDatasetName ] (_: {
            type = "zfs_fs";
            options.mountpoint = "none";
          });
          root =
            [
              "etc"
              "nix"
              "var"
              "var/lib"
              "var/log"
              "var/spool"
              "root"
            ]
            |> flip genAttrs (name: {
              type = "zfs_fs";
              options.mountpoint = "/${name}";
            })
            |> mapAttrNames' (name: "${rootDatasetName}/${name}");
          user = {
            "${userDatasetName}/${config.env.username}" = {
              type = "zfs_fs";
              options.mountpoint = "/home/${config.env.username}";
            };
          };
        in
        mergeAttrs' [
          container
          root
          user
        ];
    };
  };
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = config.disko.devices.disk.primary.content.partitions.ESP.content.mountpoint;
  };
}
