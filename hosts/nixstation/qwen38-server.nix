{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  llamaCpp = inputs.llama-cpp.packages.${pkgs.stdenv.hostPlatform.system}.vulkan;
  modelRoot = "/scary/ai-models/qwen3.8";
  officialModel = "${modelRoot}/official/Qwen3.8-27B-Q4_K_M.gguf";
  abliteratedModel = "${modelRoot}/abliterated/Qwen3.8-27B-ABLITERATED-Q4_K_S.gguf";
  apiKeySource = "${config.hyprvibe.user.home}/.config/secrets/nixstation_qwen_api_key";

  modelPresets = pkgs.writeText "qwen38-models.ini" ''
    version = 1

    [*]
    c = 16384
    parallel = 1
    threads = 6
    threads-batch = 6
    fit = on
    fit-target = 2048
    flash-attn = auto
    jinja = true

    [qwen3.8-27b]
    model = ${officialModel}
    load-on-startup = false

    [qwen3.8-27b-abliterated]
    model = ${abliteratedModel}
    load-on-startup = false
    spec-type = draft-mtp
    spec-draft-n-max = 3
  '';

  verifyModels = pkgs.writeShellScript "verify-qwen38-models" ''
    set -euo pipefail

    check_model() {
      path="$1"
      expected_size="$2"

      if [ ! -f "$path" ]; then
        echo "Qwen3.8 model is not downloaded yet: $path" >&2
        exit 1
      fi

      actual_size="$(${pkgs.coreutils}/bin/stat -c %s "$path")"
      if [ "$actual_size" -ne "$expected_size" ]; then
        echo "Qwen3.8 model has unexpected size: $path ($actual_size != $expected_size)" >&2
        exit 1
      fi
    }

    check_model ${lib.escapeShellArg officialModel} 16810714336
    check_model ${lib.escapeShellArg abliteratedModel} 15825300704
  '';
in {
  environment.systemPackages = [llamaCpp];

  systemd.services.qwen38-llama-server = {
    description = "Qwen3.8 llama.cpp OpenAI-compatible router";
    wantedBy = ["multi-user.target"];
    after = ["local-fs.target"];
    unitConfig.RequiresMountsFor = [modelRoot];

    environment = {
      HOME = "/var/lib/qwen38-llama-server";
      LLAMA_CACHE = "/var/cache/qwen38-llama-server";
    };

    serviceConfig = {
      Type = "exec";
      User = config.hyprvibe.user.name;
      Group = config.hyprvibe.user.group;
      SupplementaryGroups = [
        "video"
        "render"
      ];
      StateDirectory = "qwen38-llama-server";
      CacheDirectory = "qwen38-llama-server";
      LoadCredential = ["api-key:${apiKeySource}"];
      ExecStartPre = verifyModels;
      ExecStart = lib.concatStringsSep " " [
        "${llamaCpp}/bin/llama-server"
        "--models-preset ${modelPresets}"
        "--models-max 1"
        "--host 127.0.0.1"
        "--port 11435"
        "--api-key-file %d/api-key"
        "--sleep-idle-seconds 900"
        "--no-webui"
      ];
      Restart = "on-failure";
      RestartSec = "5min";
      Nice = 5;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = "read-only";
      ProtectSystem = "strict";
      ReadOnlyPaths = [modelRoot];
      DevicePolicy = "closed";
      DeviceAllow = [
        "/dev/dri/card0 rw"
        "/dev/dri/renderD128 rw"
      ];
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
      ];
      IPAddressDeny = "any";
      IPAddressAllow = ["localhost"];
      MemoryMax = "48G";
    };
  };

  systemd.services.qwen38-tailscale-serve = {
    description = "Tailnet HTTPS proxy for the Qwen3.8 API";
    wantedBy = ["multi-user.target"];
    after = ["tailscaled.service"];
    wants = ["tailscaled.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.tailscale}/bin/tailscale serve --yes --bg --https=443 http://127.0.0.1:11435";
      ExecStop = "-${pkgs.tailscale}/bin/tailscale serve --yes --https=443 off";
    };
  };
}
