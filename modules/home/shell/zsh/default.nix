{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    getExe'
    mkIf
    mkMerge
    mkOrder
    ;
  inherit (pkgs.stdenv) isDarwin;
in
{
  home.packages = with pkgs; [
    nix-zsh-completions
  ];
  programs = {
    zsh = {
      enable = true;
      autocd = true;
      history = {
        size = 100000;
        extended = true;
        share = true;
        ignoreDups = true;
        ignoreSpace = true;
        ignorePatterns = [
          "rm *"
          "pkill *"
          "kill *"
        ];

      };
      enableVteIntegration = true;
      enableCompletion = true;
      completionInit = ''
        zstyle ':plugin:ez-compinit' 'compstyle' 'ohmy'

        # fzf-tab config
        # disable sort when completing `git checkout`
        zstyle ':completion:*:git-checkout:*' sort false
        # set descriptions format to enable group support
        # NOTE: don't use escape sequences (like '%F{red}%d%f') here, fzf-tab will ignore them
        zstyle ':completion:*:descriptions' format '[%d]'
        # set list-colors to enable filename colorizing
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        # force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
        zstyle ':completion:*' menu no
        # preview directory's content with eza when completing cd
        zstyle ':fzf-tab:complete:cd:*' fzf-preview '${lib.getExe config.programs.lsd.package} -1 --color=always $realpath'
        # custom fzf flags
        # NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
        zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
        # To make fzf-tab follow FZF_DEFAULT_OPTS.
        # NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
        zstyle ':fzf-tab:*' use-fzf-default-opts yes
        # switch group using `<` and `>`
        zstyle ':fzf-tab:*' switch-group '<' '>'
      '';
      antidote = {
        enable = true;
        useFriendlyNames = true;
        plugins = mkMerge [
          [
            "sindresorhus/pure kind:fpath"
            "mattmc3/ez-compinit"

            "aloxaf/fzf-tab"
            "joshskidmore/zsh-fzf-history-search"
            #"marlonrichert/zsh-autocomplete"
            "mattmc3/zephyr path:plugins/color"
            "mattmc3/zephyr path:plugins/compstyle"
            "mattmc3/zephyr path:plugins/directory"
            "mattmc3/zephyr path:plugins/editor"
            "mattmc3/zephyr path:plugins/environment"
            "mattmc3/zephyr path:plugins/utility"
            "zsh-users/zsh-completions kind:fpath path:src"
            "reegnz/jq-zsh-plugin"

            "MichaelAquilina/zsh-you-should-use"
            "djui/alias-tips"
            "eventi/noreallyjustfuckingstopalready"

            "olets/zsh-abbr kind:defer"
            "zsh-users/zsh-autosuggestions kind:defer"
            "zsh-users/zsh-history-substring-search"
            "zdharma-continuum/history-search-multi-word"
            "zdharma-continuum/fast-syntax-highlighting kind:defer"

            "chrissicool/zsh-256color"
            "unixorn/warhol.plugin.zsh"
          ]
          (mkIf isDarwin [
            "mattmc3/zephyr path:plugins/homebrew"
            "mattmc3/zephyr path:plugins/macos"
            "unixorn/tumult.plugin.zsh"
          ])
        ];
      };
      dirHashes = {
        dl = "$HOME/Downloads";
        dev = "$HOME/dev";
      };
      shellAliases.myip = "${getExe pkgs.dig} +short myip.opendns.com @208.67.222.222 2>&1";
      shellGlobalAliases = {
        UUID = "$(${getExe' pkgs.utillinux "uuidgen"} -r | ${getExe' pkgs.coreutils "tr"} -d \\n)";
        G = "| ${getExe config.programs.ripgrep.package}";
        H = "| ${getExe' pkgs.coreutils "head"}";
        L = "| ${getExe pkgs.less}";
        X = "| ${getExe' pkgs.wl-clipboard "wl-copy"}";
        F = "| ${getExe config.programs.fzf.package}";
        "-?" = "--help 2>&1 | ${getExe pkgs.bat} --language=help --style=plain";
        silent = "> /dev/null 2>&1";
        noerr = "2> /dev/null";
        stdboth = "2>&1";
        "--help" = "--help 2>&1 | ${getExe pkgs.bat} --language=help --style=plain";
      };
      initContent = mkMerge [
        # Setup prompt
        (mkOrder 600 ''
          autoload -Uz promptinit && promptinit && prompt pure
        '')
        (mkOrder 610 ''
          source ${./lib.sh}
          include /etc/static/zshrc
          unsetopt nomatch
        '')
        (mkOrder 710 ''
          HISTORY_SUBSTRING_SEARCH_FUZZY=1
          HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

          bindkey "$terminfo[kcuu1]" history-substring-search-up
          bindkey "$terminfo[kcud1]" history-substring-search-down
        '')
        # uv setup
        (mkOrder 620 ''
          eval "$(${lib.getExe pkgs.uv} generate-shell-completion zsh)"
          eval "$(${lib.getExe' pkgs.uv "uvx"} --generate-shell-completion zsh)"
        '')
      ];
    };
  };
}
