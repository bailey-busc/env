{
  config,
  lib,
  pkgs,
  self,
  inputs',
  ...
}:
let
  inherit (lib)
    mkDefault
    mkForce
    mkIf
    mkMerge
    ;
  inherit (self.lib) secretsSubdirPubPath;
  hasFsType = fs: config.fileSystems |> builtins.attrValues |> builtins.any (e: e.fsType == fs);
in
{
  nix = {
    gc.automatic = true;
    optimise.automatic = true;
    settings = mkMerge [
      {
        auto-optimise-store = true;
        allowed-users = [
          "@wheel"
          config.env.username
        ];
        trusted-users = [
          "@wheel"
          config.env.username
        ];
        system-features = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
        sandbox = true;
        keep-outputs = true;
        keep-derivations = true;
        extra-experimental-features = [
          "auto-allocate-uids"
          "ca-derivations"
          "configurable-impure-env"
          "flakes"
          "impure-derivations"
          "nix-command"
          "pipe-operators"
        ];

        download-buffer-size = 500 * 1024 * 1024; # 500 MB
        fallback = true;
        min-free = 32 * 1024 * 1024 * 1024; # 32 GB
        builders-use-substitutes = true;
        http-connections = 125;
        secret-key-files = mkIf (config.age.secrets ? nix_signing_key) [
          config.age.secrets.nix_signing_key.path
        ];
        extra-trusted-public-keys =
          builtins.attrNames self.nixosConfigurations
          |> map (name: builtins.readFile <| secretsSubdirPubPath "signing" name);
      }
      # Turn on determinate nix features if determinate-nixd is present
      (mkIf (config ? determinate-nix || config ? determinate) {
        lazy-trees = true;
        lazy-locks = false;
      })
      # (mkIf (inputs' ? nix-rage) {
      #   plugin-files = "${
      #     inputs'.nix-rage.packages.default.overrideAttrs (old: {
      #       buildInputs = [
      #         config.nix.package
      #         config.nix.package.dev
      #         pkgs.boost
      #       ];
      #     })
      #   }/lib/libnix_rage.so";
      # })
    ];
    sshServe = {
      enable = true;
      trusted = true;
      keys =
        let
          inherit (config.users.users.${config.env.username}.openssh) authorizedKeys;
        in
        authorizedKeys.keys ++ (map builtins.readFile authorizedKeys.keyFiles);
    };
  };
  environment = {
    variables = {
      NIXPKGS_ALLOW_UNFREE = "1";
      NIXPKGS_ALLOW_BROKEN = "1";
    };
    pathsToLink = mkIf config.programs.zsh.enable [ "/share/zsh" ];
    enableAllTerminfo = true;
    systemPackages = mkMerge (
      with pkgs;
      [
        (mkIf (hasFsType "cifs") [ cifs-utils ])
        (mkIf (hasFsType "sshfs") [
          sshfs
          sshfs-fuse
        ])
      ]
    );
  };

  time.timeZone = mkDefault "America/New_York";

  boot = {
    kernelParams = [ "console=tty1" ];
    kernel.sysctl = {
      "kernel.sysrq" = 1;
      # Increase task limits at kernel level
      "kernel.pid_max" = 131072;
      "kernel.threads-max" = 131072;

      # Better memory management
      "vm.swappiness" = 10;
      "vm.dirty_ratio" = 15;
      "vm.dirty_background_ratio" = 5;
    };
    tmp.useTmpfs = mkDefault true;
    initrd.systemd = {
      enable = true;
      emergencyAccess = config.users.users.${config.env.username}.hashedPassword;
      tpm2.enable = true;
    };
  };
  console = {
    earlySetup = true;
    font = mkDefault "${pkgs.terminus_font}/share/consolefonts/ter-u16n.psf.gz";
    colors = config.scheme.toList;
  };
  hardware.keyboard.zsa.enable = true;
  networking.networkmanager.enable = true;
  services = {
    upower.enable = true;
    devmon.enable = true;
    udisks2.enable = true;
    # All hosts must run ssh without password auth or challenge-response
    openssh = {
      enable = mkForce true;
      startWhenNeeded = true;
      settings = {
        KbdInteractiveAuthentication = mkForce false;
        PasswordAuthentication = mkForce false;
        X11Forwarding = mkForce false;
        PermitRootLogin = mkForce "no";
        MaxAuthTries = mkForce 10;
        PubkeyAuthentication = mkForce "yes";
        AllowAgentForwarding = mkForce "no";
        AllowStreamLocalForwarding = mkForce "yes";
        AuthenticationMethods = mkForce "publickey";
      };
      banner = builtins.readFile "${self}/data/amogus.txt";
    };
    journald.extraConfig = ''
      SystemMaxUse=1G
      RuntimeMaxUse=100M
      SystemKeepFree=2G
      RuntimeKeepFree=100M
      MaxRetentionSec=1month

      # Log more detail for systemd services
      MaxLevelStore=debug
      MaxLevelSyslog=debug
    '';
  };

  programs = {
    zsh.enable = true;
    mosh = {
      enable = true;
      withUtempter = true;
      openFirewall = true;
    };
    nix-ld = {
      enable = true;
      libraries = mkMerge (
        with pkgs;
        [
          [
            gcc-unwrapped.lib
            stdenv.cc.cc.lib
            glib
            glibc
            udev
            udev.dev
          ]
          (mkIf config.hardware.graphics.enable [
            alsa-lib
            libGL

            # https://github.com/NixOS/nixpkgs/blob/1bfbbbe5bbf888d675397c66bfdb275d0b99361c/nixos/modules/hardware/opengl.nix#L13-L21
            (pkgs.buildEnv {
              name = "opengl-drivers";
              paths =
                let
                  cfg = config.hardware.graphics;
                in
                [
                  cfg.package
                ]
                ++ cfg.extraPackages;
            })
          ])
        ]
      );
    };
  };

  system.stateVersion = "25.05";
  systemd.services = {
    #nix-daemon.serviceConfig.LimitNOFILE = mkForce 99999999;
    NetworkManager-wait-online.enable = false; # Breaks deployments and nixos-rebuild switch
  };

}
