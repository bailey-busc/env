# TODO: Move to home-manager
{
  config,
  lib,

  inputs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.env.profiles.server.open-webui;
  serviceCfg = config.services.open-webui;
  ollamaEnabled = inputs.self.nixosConfigurations.orchid.config.services.ollama.enable;
  f = "False";
  t = "True";
in
{
  config = mkIf (cfg.enable && config.age.secrets ? open_webui_env) {
    services.open-webui = {
      enable = true;
      host = "0.0.0.0";
      port = 8080;
      environment = {
        # Basics
        WEBUI_URL = "http://${serviceCfg.host}:${toString serviceCfg.port}";
        ENABLE_SIGNUP = f;
        ENABLE_LOGIN_FORM = f;
        DEFAULT_LOCALE = "en";
        ENABLE_CHANNELS = t;
        # Ollama
        OLLAMA_BASE_URL = mkIf ollamaEnabled "http://${inputs.self.nixosConfigurations.orchid.config.systemd.services.ollama.environment.OLLAMA_HOST}";
        TASK_MODEL = mkIf ollamaEnabled "gemma3:4b";
        # Code
        ENABLE_CODE_EXECUTION = f;
        ENABLE_CODE_INTERPRETER = f;
      };
      # OPENAI_API_KEY,
      environmentFile = config.age.secrets.open_webui_env.path;
    };
  };
}
