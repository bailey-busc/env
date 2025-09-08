{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  settings = {
    # LLM Configuration
    llm = {
      provider = "openai/gpt-4o-mini";
      api_key_env = "OPENAI_API_KEY";
    };
    rate_limiting = {
      enabled = true;
      default_limit = "1000/minute";
      storage_uri = "memory://";
    };
    # Crawler settings
    crawler = {
      memory_threshold_percent = 95.0;
      rate_limiter = {
        base_delay = [
          1.0
          2.0
        ];
      };
      timeouts = {
        stream_init = 30.0;
        batch_process = 300.0;
      };
    };
    # Logging
    logging = {
      level = "INFO";
      format = "%(asctime)s - %(name)s - %(levelname)s - %(message)s";
    };
  };
  apartmentSubnetPrefix = "192.168";
  localSubnetPrefix = "${apartmentSubnetPrefix}.50";
  containerSubnetPrefix = "${apartmentSubnetPrefix}.18";
  defaultGateway = "${localSubnetPrefix}.1";
in
{
  services.podman = {
    enable = true;
    enableTypeChecks = true;
    autoUpdate.enable = true;
    networks.mcp = mkIf (osConfig.age.secrets ? browser_env) {
      description = "Model Context Protocol Container Network";
      driver = "bridge";
      subnet = "${containerSubnetPrefix}.0/24";
      gateway = defaultGateway;
    };
    containers.browser = mkIf (osConfig.age.secrets ? browser_env) {
      image = "docker.io/unclecode/crawl4ai:latest";
      autoStart = true;
      ports = [ "11235:11235" ];
      network = "mcp";
      ip4 = "${containerSubnetPrefix}.2";
      networkAlias = [ "browser" ];
      environmentFile = [ osConfig.age.secrets.browser_env.path ];
      extraPodmanArgs = [
        "--shm-size=1g"
        "--pull=missing"
      ];
      volumes = [
        "${(pkgs.formats.yaml { }).generate "crawl4ai-config" settings}:/app/config.yml:ro"
      ];
    };
  };
}
