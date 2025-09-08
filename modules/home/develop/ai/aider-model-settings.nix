{ pkgs, inputs, ... }:
let
  ollamaModels = inputs.self.nixosConfigurations.orchid.config.services.ollama.loadModels;
  ollamaConfig = name: {
    name = "ollama_chat/${name}";
    extra_params.num_ctx = 64 * 1024;
  };
in
(pkgs.formats.yaml { }).generate "aider-model-settings" (
  [
    {
      name = "openrouter/anthropic/claude-3-7-sonnet";
      extraParams = {
        extraHeaders = {
          "anthropic-beta" = "prompt-caching-2024-07-31,pdfs-2024-09-25,output-128k-2025-02-19";
        };
        maxTokens = 64000;
      };
      thinking = {
        type = "enabled";
        budgetTokens = 32000; # Adjust this number
      };
      cacheControl = true;
      editorModelName = "openrouter/anthropic/claude-3-7-sonnet";
      editorEditFormat = "editor-diff";
    }
    {
      name = "openrouter/anthropic/claude-sonnet-4";
      overeager = true;
      editFormat = "diff";
      weakModelName = "openrouter/anthropic/claude-3.5-haiku";
      useRepoMap = true;
      examplesAsSysMsg = true;
      extraParams = {
        extraHeaders = {
          "anthropic-beta" = "prompt-caching-2024-07-31,pdfs-2024-09-25,output-128k-2025-02-19";
        };
        maxTokens = 64000;
      };
      cacheControl = true;
      editorModelName = "openrouter/anthropic/claude-3.7-sonnet";
      editorEditFormat = "editor-diff";
      acceptsSettings = [ "thinking_tokens" ];
    }
  ]
  ++ map ollamaConfig ollamaModels
)
