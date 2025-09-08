{
  lib,
  inputs,
  config,
  pkgs,
  self,
  ...
}:
let
  inherit (config.networking) hostName domain;
  inherit (lib)
    optionals
    optional
    mkIf
    getExe
    getExe'
    recursiveUpdate
    concatLines
    mergeAttrsList
    mapAttrsToList
    escapeShellArg
    mapAttrs'
    removeSuffix
    optionalString
    concatStringsSep
    ;
  inherit (self.lib)
    genEmptyAttrs
    secretsSubdirPath
    secretsPath
    ;

  signingKeyGeneration = 1; # Increment this when the signing key is rotated
  group = "keys";
  owner = config.env.username;
  home = "/home/${owner}";

  derivationStorage = config.age.rekey.storageMode == "derivation";
  localStorage = config.age.rekey.storageMode == "local";

  paths = optional derivationStorage config.age.rekey.cacheDir;

  isIris = hostName == "iris";
  isOrchid = hostName == "orchid";
  isBackup = hostName == "backup";

  # Binaries
  wg' = getExe pkgs.wireguard-tools;
  nix' = getExe config.nix.package;
  age' = getExe pkgs.rage;

  # Helper to generate shell environment files (KEY=VALUE format)
  mkEnvFile = envVars: {
    generator = {
      dependencies = mapAttrs' (_: secretName: {
        name = secretName;
        value = config.age.secrets."${secretName}";
      }) envVars;
      script =
        {
          pkgs,
          lib,
          decrypt,
          deps,
          ...
        }:
        envVars
        |> mapAttrsToList (
          varName: secretName: ''echo "${varName}=$(${decrypt} ${escapeShellArg deps.${secretName}.file})"''
        )
        |> concatLines;
      tags = [
        "derived"
        "env"
      ];
    };
  };

  applyDefaults = lib.mapAttrs (
    name:
    recursiveUpdate {
      inherit owner group;
      rekeyFile = secretsPath name;
      mode = "440";
    }
  );
in
{
  users.groups.${group}.members = [
    owner
    "root"
  ];
  systemd.tmpfiles.rules = map (path: "d ${path} 770 ${owner} ${group}") paths;
  nix.settings.extra-sandbox-paths = paths;
  age = {
    ageBin = "PATH=$PATH:${lib.makeBinPath [ pkgs.age-plugin-yubikey ]} ${age'}";
    # ageBin = age';
    rekey = {
      hostPubkey = self.lib.keys.hosts.${hostName};
      masterIdentities = [ "${home}/.ssh/id_ed25519" ];
      extraEncryptionPubkeys = [
        "${home}/.ssh/id_ed25519.pub"
      ];
      storageMode = "local";
      localStorageDir = mkIf localStorage "${inputs.self}/data/secrets/rekeyed/${hostName}";
      cacheDir = mkIf derivationStorage "/var/lib/agenix-rekey/${
        toString config.users.users.${config.env.username}.uid
      }";
    };
    generators = {
      nix-binary-cache-key =
        { pkgs, file, ... }:
        ''
          priv=$(${nix'} key generate-secret --key-name ${hostName}.${domain}-${toString signingKeyGeneration})
          ${nix'} key convert-secret-to-public <<< "$priv" > ${
            escapeShellArg (removeSuffix ".age" file + ".pub")
          }
          echo "$priv"
        '';
      wg-priv =
        { pkgs, file, ... }:
        ''
          priv=$(${wg'} genkey)
          ${wg'} pubkey <<< "$priv" > ${escapeShellArg (removeSuffix ".age" file + ".pub")}
          echo "$priv"
        '';
    };

    secrets =
      applyDefaults
      <|
        {
          chatgpt_config.path = "${home}/.config/chatgpt/config.json";
          aws_credentials.path = "${home}/.aws/credentials";
          wireguard_private = {
            rekeyFile = secretsSubdirPath "wireguard" hostName;
            generator.script = "wg-priv";
          };
          # Open WebUI environment file
          # open_webui_env = mkEnvFile {
          #   OPENAI_API_KEY = "openai_api_key";
          #   ANTHROPIC_API_KEY = "anthropic_api_key";
          #   GOOGLE_API_KEY = "google_gemini_api_key";
          #   GROQ_API_KEY = "groq_api_key";
          #   MISTRAL_API_KEY = "mistral_ai_api_key";
          #   VOYAGE_API_KEY = "voyage_ai_api_key";
          #   OPENROUTER_API_KEY = "openrouter_api_key";
          #   DEEPSEEK_API_KEY = "deepseek_api_key";
          # };
          atticd_secret = {
            group = mkIf (config.users.groups ? ${config.services.atticd.group}) config.services.atticd.group;
            owner = mkIf (config.users.users ? ${config.services.atticd.user}) config.services.atticd.user;
            generator.script =
              { pkgs, ... }:
              "${getExe pkgs.openssl} genrsa -traditional 4096 | ${getExe' pkgs.coreutils "base64"} -w0";
          };
          atticd_env = mergeAttrsList [
            {
              group = mkIf (config.users.groups ? ${config.services.atticd.group}) config.services.atticd.group;
              owner = mkIf (config.users.users ? ${config.services.atticd.user}) config.services.atticd.user;
            }
            (mkEnvFile {
              ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64 = "atticd_secret";
              AWS_ACCESS_KEY_ID = "aws_access_key_id";
              AWS_SECRET_ACCESS_KEY = "aws_secret_access_key";
            })
          ];
          browser_env = mkEnvFile {
            ANTHROPIC_API_KEY = "anthropic_api_key";
            GEMINI_API_TOKEN = "google_gemini_api_key";
            GROQ_API_KEY = "groq_api_key";
            MISTRAL_API_KEY = "mistral_ai_api_key";
            OPENAI_API_KEY = "openai_api_key";
          };
          # Store signing keys
          nix_signing_key = {
            rekeyFile = secretsSubdirPath "signing" hostName;
            generator.script = "nix-binary-cache-key";
          };
          # Iris specific
          wireguard_iphone_private = mkIf isIris {
            rekeyFile = secretsSubdirPath "wireguard" "iphone";
            generator.script = "wg-priv";
          };
          wireguard_iphone_conf = mkIf isIris {
            rekeyFile = secretsPath "wireguard_iphone_conf";
            generator = {
              dependencies = {
                inherit (config.age.secrets) wireguard_iphone_private;
              };
              script =
                {
                  pkgs,
                  lib,
                  decrypt,
                  deps,
                  ...
                }:
                let
                  keyVar = "PRIVATE_KEY";
                  orchid = self.nixosConfigurations.orchid.config;
                  peer =
                    builtins.head
                      orchid.networking.wireguard.interfaces.${orchid.env.network.wireguard.interfaceName or "wg0"}.peers;
                  baseConfig = pkgs.writeText "base-wg-conf.m4" ''
                    [Interface]
                    PrivateKey = ${keyVar}
                    Address = 10.100.0.99/24
                    DNS = 1.1.1.1, 1.0.0.1

                    [Peer]
                    PublicKey = ${peer.publicKey}
                    ${optionalString (peer.endpoint != null) "Endpoint = ${peer.endpoint}"}
                    AllowedIPs = ${concatStringsSep ", " peer.allowedIPs}
                    PersistentKeepalive = ${toString (peer.persistentKeepalive or 25)}
                  '';
                in
                ''
                  ${getExe pkgs.m4} -D${keyVar}=$(${decrypt} ${escapeShellArg deps.wireguard_iphone_private.file}) ${baseConfig}
                '';
              tags = [ "derived" ];
            };
          };
        }
        // (
          genEmptyAttrs
          <|
            [
              "aws_access_key_id"
              "aws_secret_access_key"
              "anthropic_api_key"
              "deepseek_api_key"
              "gh_token"
              "gitconfig_home"
              "gitconfig_work"
              "google_gemini_api_key"
              "groq_api_key"
              "mistral_ai_api_key"
              "openai_api_key"
              "voyage_ai_api_key"
              "openrouter_api_key"
              "github_runner_token"
            ]
            ++ optionals isIris [
              "airvpn_wg_conf"
            ]
            ++ optionals isOrchid [
              "ctdata_credentials"
              "pipeline_env"
              "pipeline_test_env"
            ]
            ++ optionals (!isBackup) [
              "tailscale_key"
            ]
        );
  };
}
