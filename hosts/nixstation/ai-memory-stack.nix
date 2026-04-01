{ pkgs, ... }:

let
  coreLlmModel = "nemotron-3-nano";
  preloadTimeout = "48h";
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
      OLLAMA_VULKAN = "1";
    };
    extraOptions = [
      "--cpus=6"
      "--memory=16g"
      "--memory-swap=16g"
      "--device=/dev/kfd"
      "--device=/dev/dri"
      "--device=/dev/dri/card0"
      "--device=/dev/dri/renderD128"
      "--group-add=26"
      "--group-add=303"
    ];
    labels = {
      "io.containers.autoupdate" = "registry";
    };
  };

  systemd.services.ollama-models-prepull = {
    description = "Pre-pull Ollama models for nixstation";
    wantedBy = [ "multi-user.target" ];
    after = [
      "podman-ollama.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    requires = [ "podman-ollama.service" ];
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = preloadTimeout;
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "ollama-models-prepull" ''
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

            sleep_secs=$((attempt * 5))
            if [ "$sleep_secs" -gt 300 ]; then
              sleep_secs=300
            fi
            echo "Pull failed for $model, retrying in $sleep_secs s"
            sleep "$sleep_secs"
          done

          echo "Failed to pull model: $model"
          return 1
        }

        wait_for_api
        pull_with_retry "${coreLlmModel}"
      '';
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/ollama 0755 root root -"
  ];
}
