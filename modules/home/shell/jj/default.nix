{
  pkgs,
  config,
  lib,
  inputs',
  ...
}:
let
  inherit (lib) getExe;
in
{
  home.packages = with pkgs; [
    (lazyjj.override { jujutsu = config.programs.jujutsu.package; })
    (jj-fzf.override { jujutsu = config.programs.jujutsu.package; })
  ];
  programs.jujutsu = {
    enable = true;
    package = inputs'.jujutsu.packages.jujutsu.overrideAttrs (_: {
      doCheck = false;
    });
    ediff = false;
    settings = {
      user = {
        inherit (config.programs.git.extraConfig.user) name email;
      };
      ui = {
        pager = getExe config.programs.less.package;
        show-cryptographic-signatures = true;
        log-synthetic-elided-nodes = true;
      };
      signing = {
        #backend = "gpg";
      };
      git = {
        abandon-unreachable-commits = true;
        ignore-filters = [ "lfs" ];
        ignore-files = [ "lfs" ];
      };
      revset-aliases = {
        "closest_bookmark(to)" = "heads(::to & bookmarks())";
        # "bookmarks() & ~(main | remote_bookmarks())";
      };
      aliases = {
        # Advances closest bookmark to parent commit
        tug = [
          "bookmark"
          "move"
          "--from"
          "closest_bookmark(@-)"
          "--to"
          "@-"
        ];
      };

      template-aliases = {

      };

      templates = {
        log_node = ''
          coalesce(
            if(!self, label("elided", "~")),
            label(
              separate(" ",
                if(current_working_copy, "working_copy"),
                if(immutable, "immutable"),
                if(conflict, "conflict"),
              ),
              coalesce(
                if(current_working_copy, "@"),
                if(immutable, "◆"),
                if(conflict, "×"),
                if(empty, "◌"),
                "○",
              )
            )
          )
        '';
      };
      "--scope" = [
        {
          "--when"."repositories" = [
            "~/dev/glimpse-engineering/glimpse"
            "~/dev/glimpse-engineering/"
            "~/dev/glimpse"
          ];
          user.email = "bailey@glimp.se";
          signing = {
            backend = "gpg";
          };
        }
      ];
    };
  };
}
