{ pkgs, ... }:
{
  programs.awscli = {
    enable = true;
    settings =
      let
        workProfileName = "glimpse";
        workProfile = region: {
          inherit region;
          output = "json";
          sso_session = workProfileName;
          sso_account_id = 647079779938;
          sso_role_name = "PowerUserAccess";
        };
      in
      {
        "profile default" = {
          region = "us-east-1";
          output = "json";
        };
        "profile ${workProfileName}" = workProfile "us-east-1";
        "profile ${workProfileName}-west" = workProfile "us-west-1";
        "sso-session ${workProfileName}" = {
          sso_start_url = "https://d-90679b815e.awsapps.com/start#/";
          sso_region = "us-east-1";
          sso_registration_scopes = "sso:account:access";
        };
      };
  };
  home.packages = with pkgs; [
    terraform
    google-cloud-sdk

  ];
}
