{
  pkgs,
  config,
  osConfig,
  lib,
  ...
}:
let
  inherit (lib)
    mkDefault
    getExe
    mkIf
    mkMerge
    ;
  inherit (config.env) profiles;
  inherit (pkgs.stdenv) isDarwin;
in
{
  home = {
    enableNixpkgsReleaseCheck = false;
    username = mkDefault osConfig.env.username;
    homeDirectory = mkDefault "/${if isDarwin then "Users" else "home"}/${config.home.username}";

    # For macOS, $PATH must contain these.
    sessionPath = mkIf isDarwin [
      "/etc/profiles/per-user/${config.home.username}/bin" # To access home-manager binaries
      "/nix/var/nix/profiles/system/sw/bin" # To access nix-darwin binaries
      "/usr/local/bin" # Some macOS GUI programs install here
    ];

    stateVersion = "25.05";

    language.base = "en_US.UTF-8";

    # Absolute basics in the core profile
    packages = mkMerge (
      with pkgs;
      [
        [
          coreutils
          moreutils
          utillinux
          gnused
          dig
          sbctl
        ]
        (mkIf profiles.base.enable [
          # logs & systemd
          lnav
          sysz

          # json, yaml, toml
          jq
          jo
          yq
          fq
          fx
          htmlq
          miller
          jless

          # text
          choose
          sd

          # File System & Disk Management
          dosfstools
          du-dust
          duf
          gptfdisk
          parted
          udiskie

          # networking
          curl
          curlie
          dnsutils
          doggo
          dogedns
          gping
          iputils
          nmap
          wget
          whois
          xh
          netcat
          traceroute
          openssl # for utilities

          # SMB
          samba
          smbclient-ng

          # archives
          bzip2
          gzip
          lrzip
          p7zip
          unrar
          unzip
          xz

          # File Utilities & Navigation
          file

          # Development & Shell Tools
          binutils
          direnv
          shellcheck
          shfmt
          zsh-completions

          # Hardware & USB Tools
          i2c-tools
          libusb1
          inxi
          pciutils
          usbutils
          (writeShellScriptBin "facter" ''
            sudo ${getExe config.nix.package} run \
              --option experimental-features "nix-command flakes" \
              --option extra-substituters https://numtide.cachix.org \
              --option extra-trusted-public-keys numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE= \
              github:nix-community/nixos-facter -- $@
          '')

          # Backup & Sync
          restic
          rsync

          # Text Editors
          nano
          vim
        ])
        (mkIf profiles.personal.enable [
          icloudpd
        ])
      ]
    );
  };

  programs.ssh.package = mkDefault osConfig.programs.ssh.package;
  services.ssh-agent.enable = true;
}
