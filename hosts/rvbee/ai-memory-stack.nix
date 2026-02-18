{ pkgs, ... }:

let
  # Network-aware model preload policy:
  # - core models are required for service readiness
  # - optional fallback model is preloaded separately and never blocks Cognee startup
  coreLlmModel = "mistral";
  optionalLlmModel = "neural-chat";
  embeddingModel = "nomic-embed-text";

  preloadTimeout = "24h";
in
{
  virtualisation.oci-containers.containers.ollama = {
    image = "docker.io/ollama/ollama:latest";
    autoStart = true;
    pull = "newer";
    ports = [
      "127.0.0.1:11434:11434"
    ];
    volumes = [
      "/var/lib/ollama:/root/.ollama"
    ];
    environment = {
      OLLAMA_HOST = "0.0.0.0:11434";
      OLLAMA_KEEP_ALIVE = "5m";
      OLLAMA_MAX_LOADED_MODELS = "1";
      OLLAMA_NUM_PARALLEL = "1";
    };
    extraOptions = [
      "--cpus=6"
      "--memory=16g"
      "--memory-swap=16g"
    ];
    labels = {
      "io.containers.autoupdate" = "registry";
    };
  };

  virtualisation.oci-containers.containers.cognee = {
    image = "docker.io/cognee/cognee:latest";
    autoStart = true;
    pull = "newer";
    ports = [
      "127.0.0.1:8001:8000"
    ];
    volumes = [
      "/var/lib/cognee:/app/data"
    ];
    environment = {
      HOST = "0.0.0.0";
      ENV = "local";

      LLM_PROVIDER = "ollama";
      LLM_MODEL = coreLlmModel;
      LLM_ENDPOINT = "http://host.containers.internal:11434/v1";
      LLM_API_KEY = "ollama-local";

      EMBEDDING_PROVIDER = "ollama";
      EMBEDDING_MODEL = embeddingModel;
      EMBEDDING_ENDPOINT = "http://host.containers.internal:11434/v1";
      EMBEDDING_API_KEY = "ollama-local";
      EMBEDDING_DIMENSIONS = "768";
      HUGGINGFACE_TOKENIZER = "nomic-ai/nomic-embed-text-v1.5";
    };
    extraOptions = [
      "--cpus=4"
      "--memory=8g"
      "--memory-swap=8g"
    ];
    labels = {
      "io.containers.autoupdate" = "registry";
    };
  };

  # Core pre-pull: required models for a functional Cognee deployment.
  # This is idempotent, long-timeout, and retry-based for slow LTE links.
  systemd.services.ollama-models-core-prepull = {
    description = "Pre-pull core Ollama models for Cognee";
    wantedBy = [ "multi-user.target" ];
    after = [ "podman-ollama.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    requires = [ "podman-ollama.service" ];
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = preloadTimeout;
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "ollama-models-core-prepull" ''
        set -euo pipefail

        marker_dir=/var/lib/ollama/.prefetch
        mkdir -p "$marker_dir"

        wait_for_api() {
          for i in $(seq 1 360); do
            if ${pkgs.curl}/bin/curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
              return 0
            fi
            sleep 5
          done
          return 1
        }

        pull_with_retry() {
          model="$1"
          marker="$marker_dir/$model.ok"

          if [ -f "$marker" ]; then
            echo "Model already marked ready: $model"
            return 0
          fi

          for attempt in $(seq 1 120); do
            echo "Pulling $model (attempt $attempt/120)"
            if ${pkgs.podman}/bin/podman exec ollama ollama pull "$model"; then
              date -Is > "$marker"
              echo "Model ready: $model"
              return 0
            fi

            # Progressive backoff (max 5m between retries)
            sleep_secs=$((attempt * 5))
            if [ "$sleep_secs" -gt 300 ]; then
              sleep_secs=300
            fi
            echo "Pull failed for $model, retrying in $sleep_secs s"
            sleep "$sleep_secs"
          done

          echo "Failed to pull required model: $model"
          return 1
        }

        wait_for_api
        pull_with_retry "${embeddingModel}"
        pull_with_retry "${coreLlmModel}"
      '';
    };
  };

  # Optional pre-pull: useful fallback model, non-blocking for overall readiness.
  systemd.services.ollama-models-optional-prepull = {
    description = "Pre-pull optional Ollama fallback models";
    wantedBy = [ "multi-user.target" ];
    after = [ "ollama-models-core-prepull.service" ];
    requires = [ "ollama-models-core-prepull.service" ];
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = preloadTimeout;
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "ollama-models-optional-prepull" ''
        set -euo pipefail

        marker_dir=/var/lib/ollama/.prefetch
        mkdir -p "$marker_dir"

        marker="$marker_dir/${optionalLlmModel}.ok"
        if [ -f "$marker" ]; then
          echo "Optional model already marked ready: ${optionalLlmModel}"
          exit 0
        fi

        for attempt in $(seq 1 120); do
          echo "Pulling optional model ${optionalLlmModel} (attempt $attempt/120)"
          if ${pkgs.podman}/bin/podman exec ollama ollama pull "${optionalLlmModel}"; then
            date -Is > "$marker"
            echo "Optional model ready: ${optionalLlmModel}"
            exit 0
          fi

          sleep_secs=$((attempt * 5))
          if [ "$sleep_secs" -gt 300 ]; then
            sleep_secs=300
          fi
          sleep "$sleep_secs"
        done

        echo "Optional model pull failed: ${optionalLlmModel}"
        exit 1
      '';
    };
  };

  # Cognee should only depend on core model readiness.
  systemd.services.podman-cognee = {
    after = [ "ollama-models-core-prepull.service" ];
    requires = [ "ollama-models-core-prepull.service" ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/ollama 0755 root root -"
    "d /var/lib/cognee 0755 root root -"
  ];
}
