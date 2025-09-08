{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) hostName;
  localListenerName = "localbackupsink";
  defaultJob = name: {
    inherit name;
    type = "push";
    filesystems = {
      "npool/userdata<" = true;
      "spool<" = true;
      "spool/stable-diffusion<" = false;
      "spool/stable-diffusion-next<" = false;
      "spool/work<" = false;
    };
    snapshotting = {
      type = "periodic";
      interval = "30m";
      prefix = "zrepl_snap_${hostName}_";
    };
    pruning = {
      keep_sender = [
        { type = "not_replicated"; }
        {
          type = "grid";
          regex = "^zrepl_snap_${hostName}_.*";
          grid = lib.concatStringsSep " | " [
            "1x1h(keep=all)"
            "1x1h"
            "1x2h"
            "1x4h"
            "2x8h"
            "1x1d"
            "1x2d"
            "1x4d"
            "1x8d"
          ];
        }
      ];

      keep_receiver = [
        {
          type = "grid";
          regex = "^zrepl_snap_${hostName}_.*";
          grid = lib.concatStringsSep " | " [
            "2x1h(keep=all)"
            "2x1h"
            "2x2h"
            "2x4h"
            "4x8h"
            "2x1d"
            "2x2d"
            "2x4d"
            "2x8d"
            "2x16d"
            "2x32d"
            "2x64d"
            "2x128d"
          ];
        }
      ];
    };
    send = {
      compressed = true;
    };
  };
in
{
  services.zrepl = {
    enable = hostName == "iris";
    settings = {
      global = {
        logging = [
          {
            type = "syslog";
            level = "info";
            format = "human";
          }
        ];
      };
      jobs = [
        (
          (defaultJob "${hostName}_local")
          // {
            connect = {
              type = "local";
              listener_name = localListenerName;
              client_identity = hostName;
            };
          }
        )
        {
          type = "sink";
          name = hostName;
          root_fs = "backup";
          serve = {
            type = "local";
            listener_name = localListenerName;
          };
        }
      ];
    };

  };
}
