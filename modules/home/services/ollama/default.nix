{
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib) mkIf optionals;
  inherit (self.lib) ips;
  inherit (config.networking) hostName;
  inherit (config.services.ollama) loadModels;
  cfg = config.env.profiles.server.ollama;
in
{
  options.services.ollama.loadModels = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
  };
  config = mkIf cfg.enable {
    services = {
      ollama = {
        enable = true;
        acceleration = "cuda";
        host = ips.${hostName};
        loadModels = [
          "cogito:14b"
          "cogito:32b"
          "deepcoder:1.5b"
          "deepcoder:14b"
          "deepseek-r1:32b"
          "gemma3:12b"
          "gemma3:27b"
          "llama3.1:8b"
          "mxbai-embed-large:335m"
          "nomic-embed-text"
          "phi4:14b"
          "qwen2.5-coder:14b"
          "qwen2.5-coder:32b"
          "qwen2.5-coder:7b"
          "qwq:32b"
        ]
        ++ optionals (hostName == "orchid") [
          "cogito:70b"
          "deepseek-r1:70b"
          "llama3.1:70b"
          "llama3.3:70b"
        ];
      };
      # openwebui = {
      #   enable = true;
      #   package = pkgs.openwebui;
      #   environment = {
      #     ANONYMIZED_TELEMETRY = "False";
      #     DO_NOT_TRACK = "True";
      #     SCARF_NO_ANALYTICS = "True";

      #     WEBUI_AUTH_TRUSTED_EMAIL_HEADER = "Tailscale-User-Login";
      #     WEBUI_AUTH_TRUSTED_NAME_HEADER = "Tailscale-User-Name";

      #     OLLAMA_API_BASE_URL = "http://localhost:11434/api";
      #     WEBUI_AUTH_ENABLED = false;
      #     WEBUI_PORT = 3000;
      #   };
      # };
    };
    # systemd.services.ollama.after = lib.mkIf (wireguard.enable) [
    #   "wireguard-${wireguard.interfaceName}.service"
    # ];
    systemd.user.services.ollama-model-loader = lib.mkIf (loadModels != [ ]) {
      description = "Download ollama models in the background";
      wantedBy = [
        "multi-user.target"
        "ollama.service"
      ];
      after = [ "ollama.service" ];
      bindsTo = [ "ollama.service" ];
      inherit (config.systemd.services.ollama) environment;
      serviceConfig = {
        Type = "exec";
        DynamicUser = true;
        Restart = "on-failure";
        # bounded exponential backoff
        RestartSec = "1s";
        RestartMaxDelaySec = "2h";
        RestartSteps = "10";
      };

      script = ''
        total=${toString (builtins.length loadModels)}
        failed=0

        for model in ${lib.escapeShellArgs loadModels}; do
          '${lib.getExe config.services.ollama.package}' pull "$model" &
        done

        for job in $(jobs -p); do
          set +e
          wait $job
          exit_code=$?
          set -e

          if [ $exit_code != 0 ]; then
            failed=$((failed + 1))
          fi
        done

        if [ $failed != 0 ]; then
          echo "error: $failed out of $total attempted model downloads failed" >&2
          exit 1
        fi
      '';
    };
  };
}
