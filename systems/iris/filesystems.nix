{
  lib,
  pkgs,
  config,

  ...
}:
{
  boot.initrd.luks.devices = lib.listToAttrs (
    map
      (dev: {
        name = "luks-${dev}";
        value = {
          device = "/dev/disk/by-id/${dev}";
          crypttabExtraOpts = [ "tpm2-device=auto" ];
          allowDiscards = true;
          bypassWorkqueues = true;
        };
      })
      [
        "nvme-Samsung_SSD_990_PRO_2TB_S73WNJ0TB08316W" # /dev/nvme0n1
        "nvme-Samsung_SSD_970_EVO_Plus_1TB_S6S1NS0T529763N" # /dev/nvme1n1
        #"nvme-Samsung_SSD_970_EVO_Plus_2TB_S6S2NS0T623672D" # /dev/nvme3n1 - removed to move to windows
        "ata-Samsung_SSD_870_EVO_2TB_S6PNNM0TA45983F" # /dev/sdc
        #"ata-Samsung_SSD_870_EVO_2TB_S6PNNM0TA33355F" # /dev/sda - removed to move to windows
        "ata-Samsung_SSD_870_EVO_1TB_S6PTNM0RC03221H" # /dev/sdb
      ]
  );
  fileSystems =
    let
      npool = name: {
        device = "npool/${name}";
        fsType = "zfs";
        options = [
          "zfsutil"
          "X-mount.mkdir"
        ];
      };
      spool = name: {
        device = "spool/${name}";
        fsType = "zfs";
        options = [
          "zfsutil"
          "X-mount.mkdir"
        ];
      };
      sshfs = location: {
        fsType = "fuse";
        device = "${pkgs.sshfs-fuse}/bin/sshfs#bailey@${location}";
        options = [
          "noauto"
          "x-systemd.automount"
          "uid=${toString config.users.users.bailey.uid}"
          "gid=${toString config.users.groups.storage.gid}"
          "allow_other"
          "X-mount.mkdir"
        ];
      };
    in
    {
      "/" = {
        fsType = "tmpfs";
        device = "tmpfs";
        options = [
          "defaults"
          "size=64G"
          "mode=755"
        ];
      };
      "/tmp" = {
        fsType = "tmpfs";
        device = "tmpfs";
        options = [
          "nosuid"
          "nodev"
          "relatime"
          "size=64G"
          "mode=755"
        ];
      };

      "/boot" = {
        device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_2TB_S6S2NS0T623672D-part1";
        fsType = "vfat";
        options = [
          "x-systemd.idle-timeout=1min"
          "x-systemd.automount"
          "noauto"
          "nofail"
          "noatime"
          "X-mount.mkdir"
        ];
      };

      # Nix system
      "/nix" = npool "nixos/nix";
      "/etc" = npool "nixos/etc";
      "/var" = npool "nixos/var";
      "/var/lib" = npool "nixos/var/lib";
      "/var/log" = npool "nixos/var/log";
      "/var/spool" = npool "nixos/var/spool";

      # User data
      "/root" = npool "userdata/home/root";
      "/home/bailey" = npool "userdata/home/bailey";

      # Bulk
      "/data/sd" = spool "stable-diffusion";
      "/data/sd.next" = spool "stable-diffusion-next";
      "/data/media/pictures" = spool "media/pictures";
      "/data/media/videos" = spool "media/videos";
      "/data/media/music" = spool "media/music";
      "/data/work" = spool "work";
      "/data/sync" = spool "sync";

      # Remote
      "/mnt/ivy-greentown" = sshfs "ivy-greentown:/home/bailey";
    };
  swapDevices = [
    # {
    #   device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_500GB_S4P2NF0M319655L-part2";
    #   randomEncryption = {
    #     enable = true;
    #     allowDiscards = true;
    #   };
    # }
  ];
}
