{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib)
    optionals
    ;
  inherit (osConfig.networking) hostName;
  inherit (pkgs.stdenv) isDarwin isLinux;
in
{
  programs.zsh.oh-my-zsh = {
    enable = false;
    plugins = [
      "alias-finder"
      "aliases"
      "aws"
      "bgnotify"
      "colored-man-pages"
      "copyfile"
      "copypath"
      "direnv"
      "docker-compose"
      "docker"
      "encode64"
      "extract"
      "fzf"
      "gh"
      "git"
      #"gpg-agent"
      "history-substring-search"
      "history"
      "isodate"
      "lol"
      "magic-enter"
      "mosh"
      "nmap"
      "pip"
      "procs"
      "python"
      "rsync"
      "rust"
      "ssh-agent"
      "stack"
      "sudo"
      "systemadmin"
      "tailscale"
      "terraform"
      "transfer"
      "virtualenv"
      "zsh-interactive-cd"
    ]
    ++ (optionals isDarwin [
      "osx"
      "keychain"
    ])
    ++ (optionals isLinux [
      "kitty"
      "systemd"
    ])
    ++ (optionals (hostName == "azalea") [ "battery" ]);

    extraConfig = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    '';
  };
}
