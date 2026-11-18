# What: Enables the pi-coding-agent program module.
# Used by: Imported by modules/hosts/reis-new.nix (reis-new only for now; Jan is bound to 0.0.0.0 there, so the LAN IP works from gaoler containers too).
{pkgs, ...}: {
  programs.pi-coding-agent = {
    enable = true;

    extraPackages = [pkgs.nodejs];

    settings = {
      # Must match a provider/model in `models` below, so pi picks it
      # up at startup without a manual /model selection.
      defaultProvider = "jan";
      defaultModel = "ThinkingCap-Qwen3.8-27B-IQ4_XS.gguf";

      packages = [
        # https://github.com/nicobailon/pi-subagents
        "npm:pi-subagents"
        # web-research for pi
        "npm:pi-web-access"
        # https://github.com/ravshansbox/pi-statusline
        "npm:@ravshansbox/pi-statusline"
      ];
    };

    models = {
      # Jan is a local OpenAI-compatible (llama.cpp) server. Pi resolves
      # $JAN_API_KEY from the environment of the shell that starts it.
      providers.jan = {
        baseUrl = "http://192.168.10.10:1337/v1";
        api = "openai-completions";
        apiKey = "$JAN_API_KEY";

        models = [
          {
            id = "ThinkingCap-Qwen3.8-27B-IQ4_XS.gguf";
            name = "ThinkingCap Qwen3.8 27B";
            reasoning = true;
            contextWindow = 65536;
            maxTokens = 16384;
          }
          {
            id = "Qwen3.8-27B-AD-IQ4_XS-IQ3_S.gguf";
            name = "Qwen3.8 27B";
            reasoning = true;
            contextWindow = 65536;
            maxTokens = 16384;
          }
        ];
      };
    };
  };
}
