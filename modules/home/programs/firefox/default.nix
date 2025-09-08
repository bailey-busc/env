{
  pkgs,
  lib,
  self,
  config,
  ...
}:
let
  inherit (lib) getExe mkIf;
  inherit (config.env) profiles;
in
mkIf profiles.graphical.enable {
  home.file.".local/share/applications/firefox-url-handler.desktop".text = ''
    [Desktop Entry]
    Name=Firefox Safe URL Handler
    Comment=Open URLs in Firefox safely
    Exec=${(pkgs.writeShellScriptBin "firefox-safe-open" ''
      # Try to use existing window if Firefox is running
      if ${pkgs.busybox}/bin/pgrep -x "firefox" > /dev/null; then
        # Firefox is running, try to focus existing window or create a new tab
        ${getExe config.programs.firefox.finalPackage} --new-tab "$@"
      else
        # Firefox is not running, start it normally
        ${getExe config.programs.firefox.finalPackage} "$@"
      fi
    '')} %u
    Terminal=false
    Type=Application
    MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
    Categories=Network;WebBrowser;
    NoDisplay=true
  '';

  programs = {
    firefox = {
      enable = true;
      package = pkgs.firefox-bin;
      nativeMessagingHosts = with pkgs; [
        firefoxpwa
      ];
      policies =
        let
          lock = value: {
            Value = value;
            Status = "locked";
          };
          lock-false = lock false;
          lock-true = lock true;
        in
        {
          DisableTelemetry = true;
          DisablePocket = true;
          OverrideFirstRunPage = "";
          OverridePostUpdatePage = "";
          DontCheckDefaultBrowser = false;
          DefaultBrowser = true;
          DisableFirefoxStudies = true;
          EnableTrackingProtection = {
            # Value = true;
            Value = false;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };
          DisableFirefoxAccounts = true;
          DisableAccounts = true;
          DisableFirefoxScreenshots = true;
          Preferences = {
            "privacy.resistFingerprinting" = lock-false;
            # "privacy.resistFingerprinting.exemptedDomains" = lock "meet.google.com";
            "webgl.force-enabled" = lock-true;
            "extensions.pocket.enabled" = lock-false;
            "extensions.screenshots.disabled" = lock-true;
            "browser.topsites.contile.enabled" = lock-false;
            "browser.formfill.enable" = lock-false;
            "browser.search.suggest.enabled" = lock-false;
            "browser.search.suggest.enabled.private" = lock-false;
            "browser.urlbar.suggest.searches" = lock-false;
            "browser.urlbar.showSearchSuggestionsFirst" = lock-false;
            "browser.newtabpage.activity-stream.feeds.section.topstories" = lock-false;
            "browser.newtabpage.activity-stream.feeds.snippets" = lock-false;
            "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock-false;
            "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock-false;
            "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock-false;
            "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock-false;
            "browser.newtabpage.activity-stream.showSponsored" = lock-false;
            "browser.newtabpage.activity-stream.system.showSponsored" = lock-false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;
          };
        };
      profiles.${config.env.username} = {
        isDefault = true;
        settings = {
          "browser.startup.homepage" = "about:home";
          "browser.shell.checkDefaultBrowser" = false;
          "browser.tabs.remote.autostart" = true;
          "browser.tabs.remote.autostart.2" = true;
          "browser.link.open_newwindow" = 3; # Open links in a new tab instead of a new window
          "browser.link.open_newwindow.restriction" = 0;
          "browser.sessionstore.resume_from_crash" = true;
          "browser.sessionstore.resuming_after_os_restart" = true;
          "toolkit.startup.max_resumed_crashes" = -1;
          # Google meet unfuck attempt
          "media.peerconnection.enabled" = true;
        };
        search = {
          force = true;
          engines =
            let
              engine =
                {
                  url,
                  alias,
                  icon,
                  params ? { },
                }:
                {
                  inherit icon;
                  definedAliases = [ "@${alias}" ];
                  urls = [
                    {
                      template = url;
                      params = lib.mapAttrsToList (name: value: { inherit name value; }) params;
                    }
                  ];
                };
              ghEngine =
                {
                  alias,
                  lang ? null,
                  repo ? null,
                  user ? null,
                  org ? null,
                  type ? "code",
                }:
                engine {
                  inherit alias;
                  url = "https://github.com/search";
                  icon = self.lib.assets.icons.github;
                  params = {
                    q = lib.concatStringsSep " " [
                      "{searchTerms}"
                      (lib.optionalString (lang != null) "lang:${lang}")
                      (lib.optionalString (repo != null) "repo:${repo}")
                      (lib.optionalString (user != null) "user:${user}")
                      (lib.optionalString (org != null) "user:${org}")
                    ];
                  }
                  // lib.optionalAttrs (type != null) {
                    inherit type;
                  };
                };
            in
            {
              "Nix Packages" = engine {
                url = "https://search.nixos.org/packages";
                alias = "np";
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                params = {
                  sort = "relevance";
                  query = "{searchTerms}";
                };
              };
              "Nix Options" = engine {
                url = "https://search.nixos.org/options";
                alias = "no";
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                params = {
                  sort = "relevance";
                  query = "{searchTerms}";
                };
              };
              "GitHub" = ghEngine { alias = "gh"; };
              "NixHub" = ghEngine {
                alias = "ghn";
                lang = "Nix";
              };
              "bing".metaData.hidden = true;
              "google".metaData.alias = "@g"; # builtin engines only support specifying one additional alias
            };
        };
      };
    };
  };
}
