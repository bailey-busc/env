{
  pkgs,
  osConfig,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    optional
    getExe
    flatten
    ;
  inherit (osConfig.age) secrets;
  ghUsername = "bailey-busc";
in
{
  home.packages = with pkgs; [
    git-up
    git-crypt
    glab
  ];

  programs = {
    gh.enable = true;
    git-worktree-switcher.enable = true;
    git = {
      enable = true;
      lfs.enable = true;
      difftastic = {
        enable = true;
        background = "dark";
      };
      ignores = [
        "*~"
        ".DS_Store"
        "*.swp"
      ];
      includes = flatten [
        (optional (secrets ? gitconfig_work) {
          inherit (secrets.gitconfig_work) path;
          condition = "hasconfig:remote.*.url:git@github.com\:glimpse-engineering/**";
        })
      ];
      extraConfig = {
        user = {
          name = "Bailey Buscarino";
          email = "2858049+${ghUsername}@users.noreply.github.com";
        };
        core = {
          fsmonitor = true;
          untrackedCache = true;
        };
        column.ui = "auto";
        branch.sort = "-committerdate";
        tag.sort = "version:refname";
        init.defaultBranch = "main";
        diff = {
          algorithm = "histogram";
          colorMoved = "plain";
          mnemonicPrefix = true;
          renames = true;
        };
        push = {
          default = "simple";
          autoSetupRemote = true;
          followTags = true;
        };
        fetch = {
          prune = true;
          pruneTags = true;
          all = true;
        };
        help.autocorrect = "prompt";
        commit.verbose = true;
        rerere = {
          enabled = true;
          autoupdate = true;
        };
        pull = {
          rebase = true;
        };
        rebase = {
          autoStash = true;
          autoSquash = true;
          updateRefs = true;
        };
        merge.conflictStyle = "zdiff3";

        "filter \"lfs\"" = {
          clean = "${getExe pkgs.git-lfs} clean -- %f";
          smudge = "${getExe pkgs.git-lfs} smudge --skip -- %f";
          process = "${getExe pkgs.git-lfs} filter-process --skip";
          required = true;
        };
        url =
          [
            "glimpse-engineering"
            "${ghUsername}/.system"
            "${ghUsername}/env"
          ]
          |> map (name: {
            name = "ssh://git@github.com/${name}";
            value = {
              insteadOf = "https://github.com/${name}";
            };
          })
          |> builtins.listToAttrs;
      };

      aliases = {
        a = "add -p";
        co = "checkout";
        cob = "checkout -b";
        f = "fetch -p";
        c = "commit";
        p = "push";
        ba = "branch -a";
        bd = "branch -d";
        bD = "branch -D";
        d = "diff";
        dc = "diff --cached";
        ds = "diff --staged";
        r = "restore";
        rs = "restore --staged";
        st = "status -sb";

        # reset
        soft = "reset --soft";
        hard = "reset --hard";
        s1ft = "soft HEAD~1";
        h1rd = "hard HEAD~1";

        # logging
        lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        plog = "log --graph --pretty='format:%C(red)%d%C(reset) %C(yellow)%h%C(reset) %ar %C(green)%aN%C(reset) %s'";
        tlog = "log --stat --since='1 Day Ago' --graph --pretty=oneline --abbrev-commit --date=relative";
        rank = "shortlog -sn --no-merges";

        # delete merged branches
        bdm = "!git branch --merged | grep -v '*' | xargs -n 1 git branch -d";
      };
    };
  };
}
