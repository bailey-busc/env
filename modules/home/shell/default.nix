{
  lib,
  config,
  pkgs,
  self,
  osConfig,
  ...
}:
let
  inherit (lib)
    getExe
    getExe'
    optionalAttrs
    concatStringsSep
    concatMap
    mergeAttrsList
    genAttrs
    mkMerge
    mkIf
    isDerivation
    ;
  inherit (self.lib) filterMapAttrVals optional' filterNullAttrs;
  inherit (osConfig.networking) hostName;
  inherit (pkgs.stdenv) isLinux isDarwin;
  inherit (pkgs) writeShellScript;
  inherit (config.env) profiles;
  inherit (config.env.profiles) dev;

  coreutilsBin = getExe' pkgs.coreutils;

  cmds = {
    ag = getExe pkgs.silver-searcher;
    cat = getExe pkgs.bat;
    df = getExe pkgs.duf;
    dig = getExe' pkgs.dnsutils "dig";
    du = getExe pkgs.du-dust;
    echo = coreutilsBin "echo";
    emacsclient = lib.getExe' config.programs.doom-emacs.finalEmacsPackage "emacsclient";
    fd = getExe config.programs.fd.package;
    git = getExe config.programs.git.package;
    grep = getExe config.programs.ripgrep.package;
    head = coreutilsBin "head";
    journalctl = getExe' osConfig.systemd.package "journalctl";
    jq = getExe pkgs.jq;
    ls = getExe pkgs.lsd;
    manix = getExe pkgs.manix;
    mkdir = coreutilsBin "mkdir";
    mktemp = coreutilsBin "mktemp";
    mv = coreutilsBin "mv";
    nix = getExe osConfig.nix.package;
    nixfmt = getExe pkgs.nixfmt-rfc-style;
    nixos-rebuild = getExe osConfig.system.build.nixos-rebuild;
    perl = getExe pkgs.perl;
    printf = coreutilsBin "printf";
    ps = getExe pkgs.procs;
    readlink = coreutilsBin "readlink";
    sed = coreutilsBin "sed";
    sk = getExe config.programs.skim.package;
    sudo = "sudo";
    systemctl = getExe' osConfig.systemd.package "systemctl";
    systemd-cryptenroll = getExe' osConfig.systemd.package "systemd-cryptenroll";
    top = getExe config.programs.btop.package;
    tr = coreutilsBin "tr";
    xargs = getExe' pkgs.findutils "xargs";
    xdg-open = getExe' pkgs.xdg-utils "xdg-open";
    zellij = getExe config.programs.zellij.package;
  };
in

{
  home = {
    sessionVariables =
      filterNullAttrs
      <| {
        _ZO_ECHO = optional' config.programs.zoxide.enable "1";
        PAGER = getExe config.programs.less.package;
        LESS = "-iFJMRWX -z-4 -x4";
      };
    packages = mkMerge (
      with pkgs;
      [
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
        (mkIf dev.nix.enable [
          deadnix
          nil
          nix-bisect
          nix-diff
          nix-du
          nix-fast-build
          (nix-init.override { nix = osConfig.nix.package; })
          nix-melt
          nix-output-monitor
          nix-prefetch-git
          nix-prefetch-github
          nix-prefetch-scripts
          nix-top
          nix-web
          nvd
          nixdoc
          nixfmt-rfc-style
          nixos-generators
          (nurl.override { nixForLinking = osConfig.nix.package; })
          # (nurl.override { nix = osConfig.nix.package; })
          fh
        ])
        (mkIf profiles.personal.enable [
          icloudpd
        ])
        (mkIf isDarwin [
          terminal-notifier
        ])
      ]
    );
    shellAliases =
      filterMapAttrVals isDerivation builtins.toString
      <| mergeAttrsList [
        {
          inherit (cmds)
            top
            cat
            df
            du
            ls
            ps
            grep
            ;

          # git
          g = cmds.git;

          # grep
          gi = "${cmds.grep} -i";

          # nix
          n = cmds.nix;
          np = "n profile";
          ni = "np install";
          nimp = "ni --impure";
          nr = "np remove";
          nb = "n build --no-link";
          nbj = "nb --json";
          nbo = writeShellScript "nix-build-output" ''${cmds.nix} build --no-link --json $@ | ${cmds.jq} -r ".[].outputs.out"'';
          ns = "n search --no-update-lock-file";
          nf = "n flake";
          nfmt = writeShellScript "nfmt" ''
            dir="''${1:-.}"
            ${cmds.fd} ".*\.nix$" "$dir" -t f -x ${cmds.nixfmt} {}
          '';
          nrpl = "n repl";
          srch = "ns nixpkgs";
          jsonfmt = writeShellScript "json-formatter" ''
            # Check if a filename is provided as an argument
            if [ $# -eq 0 ]; then
               ${cmds.echo} "Usage: jsonfmt <json_filename>"
               exit 1
            fi

            json_filename="$1"

            # Check if the provided file exists
            if [ ! -f "$json_filename" ]; then
               ${cmds.echo} "File '$json_filename' not found."
               exit 1
            fi

            # Use jq to format the JSON file in place
            # Create a temporary file
            temp_file=$(${cmds.mktemp})

            ${cmds.jq} . "$json_filename" > "$temp_file"
            ${cmds.mv} "$temp_file" "$json_filename"
          '';
          which = writeShellScript "nix-which" "${cmds.readlink} -f `${getExe pkgs.which} $1`";
          nis = writeShellScript "nix-issues-search" "${cmds.xdg-open} https://github.com/NixOS/nixpkgs/issues?q=$(${cmds.printf} \" %s\" \"$@\" | ${cmds.jq} -sRr @uri)";
          neval = writeShellScript "nix-eval" "${cmds.nix} eval --impure --raw $1";

          nps = writeShellScript "nix-package-search" "${cmds.xdg-open} https://search.nixos.org/packages?query=$(${cmds.printf} \" %s\" \"$@\" | ${cmds.jq} -sRr @uri)";

          mn = ''
            ${cmds.manix} "" | ${cmds.grep} '^# ' | ${cmds.sed} 's/^# \(.*\) (.*/\1/;s/ (.*//;s/^# //' | ${cmds.sk} --preview="${cmds.manix} '{}'" | ${cmds.xargs} ${cmds.manix}
          '';

          rhex = writeShellScript "random-hex" ''
            # Check if argument is provided
            if [ $# -eq 0 ]; then
                echo "Usage: $0 <number_of_hex_characters>" >&2
                exit 1
            fi

            # Get the number of hex characters from first argument
            n="$1"

            # Validate that the argument is a positive integer
            if ! [[ "$n" =~ ^[0-9]+$ ]] || [ "$n" -eq 0 ]; then
                echo "Error: Please provide a positive integer" >&2
                exit 1
            fi

            # Generate random hex characters
            # We generate enough bytes to ensure we have at least n hex characters
            # Each byte produces 2 hex characters, so we need at least (n+1)/2 bytes
            bytes_needed=$(( (n + 1) / 2 ))

            # Generate random hex and truncate to exactly n characters
            ${lib.getExe pkgs.openssl} rand -hex "$bytes_needed" | ${cmds.head} -c "$n"
          '';

          replace = writeShellScript "ag-replace" ''
            ${cmds.ag} -o -l $1 | ${cmds.xargs} -0 ${cmds.perl} -pi.bak -e "s/$1/$2/g"
          '';
          run = writeShellScript "run" ''
            nix run "nixpkgs#''${1}" -- "''${@:2}"
          '';
          rl = cmds.readlink;
          rlr = cmds.readlink + " -f";

          resettpm = writeShellScript "resettpm" (
            [
              "nvme0n1"
              "nvme1n1"
              "sda"
              "sdc"
            ]
            |> concatMap (dev: [
              "${cmds.sudo} ${cmds.systemd-cryptenroll} --wipe-slot tpm2 /dev/${dev}"
              "${cmds.sudo} ${cmds.systemd-cryptenroll} --tpm2-device=auto /dev/${dev}"
            ])
            |> concatStringsSep "\n"
          );

          # sudo
          s = "${cmds.sudo} -E";
          si = "${cmds.sudo} -i";
          se = osConfig.security.wrapperDir + "/sudoedit";

          rz = "exec zsh || exec ${getExe config.programs.zsh.package}";
          rzl = "${cmds.zellij} ka -y; ${cmds.zellij} da -y; ${cmds.zellij} --session ${hostName}";

          mg = "${cmds.emacsclient} -nw -e '(magit-status)'";

          aws-secret-to-env = writeShellScript "aws-secret-to-env" ''
            # Set the name of the secret and the region
            SECRET_NAME="''${2}"
            REGION="''${1}"

            # Fetch the secret value from AWS Secrets Manager
            SECRET_VALUE=$(${pkgs.awscli2}/bin/aws secretsmanager get-secret-value --secret-id $SECRET_NAME --region $REGION --query SecretString --output text)

            # Check if the command was successful
            if [ $? -ne 0 ]; then
                echo "Failed to fetch secret value from AWS Secrets Manager"
                exit 1
            fi

            # Use jq to parse the JSON and format it as .env variables
            echo $SECRET_VALUE | ${pkgs.jq}/bin/jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" > .env

            # Check if .env file was successfully created
            if [ $? -eq 0 ]; then
                echo ".env file has been successfully created."
            else
                echo "Failed to create .env file."
                exit 1
            fi
          '';
        }
        (optionalAttrs isLinux rec {
          # systemd
          ctl = cmds.systemctl;
          stl = "${cmds.sudo} ${ctl}";
          utl = "${ctl} --user";
          ut = "${ctl} --user start";
          un = "${ctl} --user stop";
          up = "${stl} start";
          dn = "${stl} stop";
          jtl = cmds.journalctl;
        })
      ];

  };

  programs = {
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks."*" = {
        forwardAgent = false;
        addKeysToAgent = "no";
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
      extraConfig = ''
        UseRoaming no
      '';
    };
    nh = {
      enable = true;
      flake = "${config.home.homeDirectory}/env";
      clean.enable = true;
      clean.extraArgs = "--keep-since 14d --keep 3";
    };

    nix-index.enable = true;

    command-not-found.enable = false;

    zoxide.enable = true;

    broot = {
      enable = true;
      # TODO: https://dystroy.org/broot/conf_file/
      settings = {
        verbs = [
          {
            invocation = "edit";
            key = "ctrl-e";
            shortcut = "e";
            execution = "$EDITOR {file}";
            apply_to = "text_file";
            leave_broot = false;
          }
        ];
        syntax_theme = "GitHub";
        terminal_title = "{file} 🐄";
        # ext_colors = {
        #   png = "";
        #   rs = "";
        #   toml = "";
        # };
        cols_order = [
          "mark"
          "git"
          "branch"
          "permission"
          "date"
          "size"
          "count"
          "name"
        ];
        special_paths =
          let
            nosum =
              genAttrs
                [
                  "target"
                ]
                (_: {
                  show = "default";
                  list = "default";
                  sum = "never";
                });
            noshow =
              genAttrs
                [
                  ".git"
                ]
                (_: {
                  show = "never";
                  list = "never";
                  sum = "never";
                });
          in
          mergeAttrsList [
            nosum
            noshow
          ];
        preview_transformers = [
          {
            input_extensions = [ "pdf" ];
            output_extension = "png";
            mode = "image";
            command = [
              (getExe' pkgs.mupdf-headless "mutool")
              "draw"
              "-w"
              "1000"
              "-o"
              "{output-path}"
              "{input-path}"
              "1"
            ];
          }
          {
            input_extensions = [ "json" ];
            output_extension = "json";
            mode = "text";
            command = [ cmds.jq ];
          }
          {
            input_extensions = [
              "xls"
              "xlsx"
              "doc"
              "docx"
              "ppt"
              "pptx"
              "ods"
              "odt"
              "odp"
            ];
            output_extension = "png";
            mode = "image";
            command = [
              (getExe pkgs.libreoffice)
              "--headless"
              "--convert-to"
              "png"
              "--outdir"
              "{output-dir}"
              "{input-path}"
            ];
          }
        ];
      };
    };
    lazydocker = {
      enable = true;
    };
    lazygit = {
      enable = true;
    };
    lsd = {
      enable = true;
      settings = {
        date = "relative";
        ignore-globs = [
          ".git"
          ".hg"
        ];
      };
    };
    less = {
      enable = true;
      package = pkgs.less;
    };
    lesspipe.enable = true;
    bat = {
      enable = true;
      config.pager = "${config.home.sessionVariables.PAGER} -FR";
      syntaxes = { };
      themes = { };
      extraPackages = [ ];
    };
    fzf = {
      enable = true;
      defaultCommand = "${cmds.fd} --type=f --hidden --exclude=.git";
      defaultOptions = [
        "--inline-info"
        "--reverse"
        "--height=30"
        "--header-first"
      ];
      changeDirWidgetCommand = "${cmds.fd} --type=d --hidden --exclude=.git";
      changeDirWidgetOptions = [
        "--preview '${getExe config.programs.lsd.package} --tree --level 5 {} | head -200'"
      ];
    };
    fd = {
      enable = true;
    };
    ripgrep = {
      enable = true;
    };
    ripgrep-all = {
      enable = true;
    };
    skim.enable = true;
    hyfetch = {
      enable = true;
      settings = {
        preset = "transfeminine";
        mode = "rgb";
        color_align = {
          mode = "horizontal";
        };
      };
    };
  };
}
