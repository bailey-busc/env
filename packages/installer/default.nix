{ machineAttr, inputs, ... }:
{
  lib,
  writeShellScriptBin,
  jq,
  deploy-rs,
  git,
  openssh,
  choose,
  agenix,
  iproute2,
  gnugrep,
  coreutils,
  closureInfo,
  disko,
  zfs,
  ...
}:

let
  inherit (lib) mkIf;
  inherit (inputs.self.lib.modules) disabled enabled;
  machine = inputs.self.nixosConfigurations.${machineAttr};
  config = machine.config;
  dependencies = [
    machine.config.system.build.toplevel
    machine.config.system.build.diskoScript
    machine.config.system.build.diskoScript.drvPath
    machine.pkgs.stdenv.drvPath

    # https://github.com/NixOS/nixpkgs/blob/f2fd33a198a58c4f3d53213f01432e4d88474956/nixos/modules/system/activation/top-level.nix#L342
    machine.pkgs.perlPackages.ConfigIniFiles
    machine.pkgs.perlPackages.FileSlurp

    (machine.pkgs.closureInfo { rootPaths = [ ]; }).drvPath
  ]
  ++ builtins.map (i: i.outPath) (builtins.attrValues inputs.self.inputs);

  closureInfo = machine.pkgs.closureInfo { rootPaths = dependencies; };
  install = writeShellScriptBin "nixos-install-unattended" ''
    set -eux
    ${disko}/bin/disko --flake "${inputs.self}#${machineAttr}" -m destroy,format,mount --yes-wipe-all-disks

    # For some reason we need to export and import again, or else the files will never actually be written to the disk???
    sudo ${zfs}/bin/zpool export -fa
    sudo ${zfs}/bin/zpool import -R /mnt ${machine.config.glimpse.partitioning.pool.name}

    ${config.system.build.nixos-install}/bin/nixos-install --system ${machine.config.system.build.toplevel} --cores 0 $@
  '';
  colors = {
    green = "\\033[0;32m";
    red = "\\033[0;31m";
    blue = "\\033[0;34m";
    noColor = "\\033[0m";
  };
  cmds = {
    agenix = lib.getExe agenix;
    choose = lib.getExe choose;
    deploy-rs = lib.getExe deploy-rs;
    git = lib.getExe git;
    grep = lib.getExe gnugrep;
    ssh = lib.getExe' openssh "ssh";
    ssh-keyscan = lib.getExe' openssh "ssh-keyscan";
    tail = lib.getExe' coreutils "tail";
  };
in

writeShellScriptBin "${machineAttr}-installer" ''
  set -euo pipefail

  log_info() {
    echo -e "🔄 ''${blue}$1''${noColor}"
  }

  log_success() {
    echo -e "✅ ''${green}$1''${noColor}"
  }

  log_error() {
    echo -e "❌ ''${red}$1''${noColor}" >&2
  }

  # Print usage and exit with error
  usage() {
    log_error "Full bootstrap from any networked NixOS installer"
    log_error "Usage: $0 <ip_address> <hostname>"
    exit 1
  }

  # Validate input arguments
  if [ $# -ne 2 ]; then
    usage
  fi

  readonly IP_ADDRESS="$1"
  readonly HOSTNAME="$2"
  readonly KEY_PATH="data/keys/hosts/$HOSTNAME.pub"
  readonly REPO_ROOT="$(${cmds.git} rev-parse --show-toplevel)"

  log_info "Performing pre-flight checks..."
  if [ -n "$(${cmds.git} diff-index --quiet HEAD || echo "changed")" ]; then
    log_error "Git working directory has uncommitted changes to tracked files. Please commit or stash changes first."
    exit 1
  fi
  log_success "Git working directory is clean"

  log_info "Checking for existing host key..."
  if [ -f "$KEY_PATH" ]; then
    log_error "Found existing key file at $KEY_PATH"
    exit 1
  fi
  log_success "No existing host key found"

  log_info "Updating known_hosts..."
  ${cmds.ssh-keyscan} "$IP_ADDRESS" 2>/dev/null >> ~/.ssh/known_hosts || {
    log_error "Failed to update known_hosts for $IP_ADDRESS"
    exit 1
  }
  log_success "Known hosts updated"

  ${cmds.nix} copy --to "ssh://$USER@$IP_ADDRESS" ${install} ${inputs.self} ${machine}



  log_info "Verifying ability to ssh..."
  if ! ${cmds.ssh} "$IP_ADDRESS" exit >/dev/null 2>&1; then
    log_error "Failed to ssh"
    exit 1
  fi
  log_success "User login successful"

  log_info "Fetching SSH key from target host..."
  KEY_CONTENT="$(${cmds.ssh-keyscan} -t ed25519 "$IP_ADDRESS" 2>/dev/null | \
                 ${cmds.tail} -n 1 | \
                 ${cmds.choose} 1 2)" || {
    log_error "Failed to fetch SSH key from $IP_ADDRESS"
    exit 1
  }

  if [ -z "$KEY_CONTENT" ]; then
    log_error "Empty SSH key received from $IP_ADDRESS"
    exit 1
  fi
  log_success "SSH key fetched successfully"

  log_info "Writing key content to file..."
  if ! echo "$KEY_CONTENT" > "$KEY_PATH"; then
    log_error "Failed to write key content to $KEY_PATH"
    exit 1
  fi
  log_success "Key content written to file"

  log_info "Adding key file to git..."
  if ! ${cmds.git} add "$KEY_PATH"; then
    log_error "Failed to add $KEY_PATH to git"
    exit 1
  fi
  log_success "Key file added to git"

  log_info "Rekeying secrets..."
  if ! (cd "$REPO_ROOT/nix/secrets" && ${cmds.agenix} --rekey); then
    log_error "Failed to rekey secrets"
    exit 1
  fi
  log_success "Secrets rekeyed successfully"

  log_info "Adding .age files to git..."
  if ! ${cmds.git} add "$REPO_ROOT/nix/secrets/*.age"; then
    log_error "Failed to add .age files to git"
    exit 1
  fi
  log_success ".age files added to git"

  log_info "Note: When prompted for a sudo password, please use the sudo password of the remote machine at $IP_ADDRESS"

  log_info "Getting ready for secureboot..."
  if ! ${cmds.ssh} -t "$IP_ADDRESS" "sudo nix profile install nixpkgs#sbctl nixpkgs#busybox nixpkgs#fd"; then
    log_error "Failed to install utilities"
    exit 1
  fi

  if ! ${cmds.ssh} -t "$IP_ADDRESS" "sudo bootctl status | grep -q 'Secure Boot: enabled'"; then
    log_info "Secure Boot not enabled, setting up..."
    if ! ${cmds.ssh} -t "$IP_ADDRESS" "sudo bash -c 'bootctl install && sbctl create-keys && chattr -i \$(fd \"^(KEK|db)-?.*\" /sys/firmware/efi/efivars/) && sbctl enroll-keys --microsoft'"; then
      log_error "Failed to set up secureboot"
      exit 1
    fi
  fi
  log_success "Prepped for secureboot successfully"

  log_info "Deploying to target host..."
  if ! ${cmds.deploy-rs} --hostname "$IP_ADDRESS" ".#$HOSTNAME"; then
    log_error "Deployment failed"
    exit 1
  fi
  log_success "Deployment completed"

  log_info "Committing changes from deployment..."
  if ! ${cmds.git} add . && \
       ${cmds.git} commit -m "Deploy $HOSTNAME and rekey secrets"; then
    log_error "Failed to commit changes"
    exit 1
  fi
  log_success "Changes committed successfully"
  log_success "Successfully deployed $HOSTNAME and rekeyed secrets"

  log_info "Rebooting target host..."
  ${cmds.ssh} -t "$IP_ADDRESS" "sudo reboot" || true

  log_info "Waiting for host to become available..."
  while ! ${cmds.ssh} -q "$IP_ADDRESS" exit >/dev/null 2>&1; do
    sleep 5
  done
  log_success "Host is back online"

  log_info "Setting up TPM2-based disk decryption..."
  if ! ${cmds.ssh} -t "$IP_ADDRESS" "sudo systemd-cryptenroll /dev/disk/by-partlabel/disk-primary-zfs --tpm2-device=auto --tpm2-pcrs=7"; then
    log_error "Failed to set up TPM2 disk decryption"
    exit 1
  fi
  log_success "TPM2 disk decryption configured successfully"

  log_info "Rebooting target host..."
  ${cmds.ssh} -t "$IP_ADDRESS" "sudo reboot" || true

  log_info "Waiting for host to become available..."
  while ! ${cmds.ssh} -q "$IP_ADDRESS" exit >/dev/null 2>&1; do
    sleep 5
  done
  log_success "Host is back online, installation complete!"
''
