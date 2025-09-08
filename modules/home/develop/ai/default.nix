{
  pkgs,
  lib,
  osConfig,
  inputs,
  self,

  ...
}@modArgs:
let
  inherit (pkgs)
    stdenv
    writeShellScriptBin
    wrapProgram
    ;
  inherit (stdenv)
    isLinux
    ;
  inherit (lib)
    optionalAttrs
    getExe
    getExe'
    mkIf
    mkMerge
    mergeAttrsList
    ;
  inherit (self.lib)
    mapAttrVals
    ;
  ollamaEnabled = inputs.self.nixosConfigurations.orchid.config.services.ollama.enable;
  inherit (inputs.self.nixosConfigurations.orchid.config.systemd.services.ollama.environment)
    OLLAMA_HOST
    ;
  aider =
    wrapProgram pkgs.aider-chat-full
    <| mergeAttrsList [
      (mapAttrVals
        (secretName: "$(${getExe' pkgs.coreutils "cat"} ${osConfig.age.secrets.${secretName}.path})")
        {
          OPENAI_API_KEY = "openai_api_key";
          ANTHROPIC_API_KEY = "anthropic_api_key";
          GEMINI_API_KEY = "google_gemini_api_key";
          GROQ_API_KEY = "groq_api_key";
          OPENROUTER_API_KEY = "openrouter_api_key";
        }
      )
      (optionalAttrs ollamaEnabled {
        OLLAMA_API_BASE = "http://${OLLAMA_HOST}";
      })
    ];

in
{
  home = {
    sessionVariables = mkIf ollamaEnabled {
      inherit OLLAMA_HOST;
    };

    packages = mkMerge [
      (mkIf (stdenv.hostPlatform.isx86 && isLinux) (
        with pkgs;
        [
          # LLMs lol
          code2prompt
          repomix
          # python312.pkgs.crawl4ai
          python313.pkgs.llm
          aider
          (writeShellScriptBin "aider-opus" ''
            ${getExe aider} --model "openrouter/anthropic/claude-4-opus"
          '')
        ]
      ))
      (mkIf ollamaEnabled [
        (wrapProgram pkgs.ollama {
          OLLAMA_API_BASE = "http://${OLLAMA_HOST}";
        })
      ])
    ];
    file = {
      ".aider.model.setting.yml".source = import ./aider-model-settings.nix modArgs;
      ".aider.conf.yml".source = import ./aider-config.nix modArgs;
    };
  };
}
