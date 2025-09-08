{ pkgs, inputs, ... }:
let
  ollamaEnabled = inputs.self.nixosConfigurations.orchid.config.services.ollama.enable;
  local = {
    model = "ollama_chat/cogito:70b";
    editor-model = "ollama_chat/deepcoder:14b";
    weak-model = "ollama_chat/gemma3:12b";
  };
  api = {
    model = "openrouter/anthropic/csonnet-4";
    editor-model = "openrouter/anthropic/claude-3.7-sonnet";
    weak-model = "openrouter/anthropic/claude-3.5-haiku";
  };
in
(pkgs.formats.yaml { }).generate "aider-config"
<|
  {
    attribute-author = false;
    attribute-commit-message-author = true;
    attribute-committer = false;
    check-update = false;
    cache-prompts = true;
    cache-keepalive-pings = 1;
    dark-mode = true;
    git = true;
    gitignore = true;
    install-main-branch = false;
    pretty = true;
    stream = true;
    upgrade = false;
    vim = true;
    voice-language = "en";
  }
  // (if ollamaEnabled then local else api)
