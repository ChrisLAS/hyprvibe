{ pkgs, inputs, ... }:

let
  coreLlmModel = "nemotron-3-nano";
  preloadTimeout = "48h";
  pgSearchNixpkgs = import inputs.nixpkgsPgsearch {
    system = pkgs.stdenv.system;
    config.allowUnfree = true;
  };
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

  services.postgresql = {
    enable = true;
    package = pgSearchNixpkgs.postgresql_17;
    extensions = with pgSearchNixpkgs.postgresql_17.pkgs; [
      pgvector
      pg_search
    ];
    ensureDatabases = [ "lobehub" ];
    ensureUsers = [
      {
        name = "lobehub";
      }
    ];
    authentication = ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
    initialScript = pkgs.writeText "lobehub-init.sql" ''
      ALTER USER lobehub WITH SUPERUSER;
      ALTER USER lobehub WITH PASSWORD 'lobehub-secret';
      GRANT ALL PRIVILEGES ON DATABASE lobehub TO lobehub;
      GRANT ALL ON SCHEMA public TO lobehub;
    '';
  };

  virtualisation.oci-containers.containers.redis = {
    image = "docker.io/redis:7-alpine";
    autoStart = true;
    ports = [
      "127.0.0.1:6379:6379"
    ];
    volumes = [
      "redis-data:/data"
    ];
    cmd = [
      "redis-server"
      "--appendonly"
      "yes"
    ];
    labels = {
      "io.containers.autoupdate" = "registry";
    };
  };

  virtualisation.oci-containers.containers.minio = {
    image = "docker.io/minio/minio:latest";
    autoStart = true;
    ports = [
      "127.0.0.1:9000:9000"
      "127.0.0.1:9001:9001"
    ];
    volumes = [
      "minio-data:/data"
    ];
    cmd = [
      "server"
      "/data"
      "--console-address"
      ":9001"
    ];
    environment = {
      MINIO_ROOT_USER = "lobehub";
      MINIO_ROOT_PASSWORD = "lobehub-minio-secret";
    };
    labels = {
      "io.containers.autoupdate" = "registry";
    };
  };

  virtualisation.oci-containers.containers.lobehub = {
    image = "docker.io/lobehub/lobehub:latest";
    autoStart = true;
    pull = "newer";
    ports = [
      "127.0.0.1:3210:3210"
    ];
    environment = {
      OLLAMA_BASE_URL = "http://127.0.0.1:11434";
      DATABASE_URL = "postgresql://lobehub:lobehub-secret@localhost:5432/lobehub";
      REDIS_URL = "redis://127.0.0.1:6379";
      S3_ENDPOINT = "http://127.0.0.1:9000";
      S3_REGION = "us-east-1";
      S3_BUCKET = "lobehub";
      S3_ACCESS_KEY_ID = "lobehub";
      S3_SECRET_ACCESS_KEY = "lobehub-minio-secret";
      S3_ENABLE_PATH_STYLE = "true";
      KEY_VAULTS_SECRET = "/ytytLi5JVMIYeSTAFiv3yP+uD+tdDiH4oWknKqSt/U=";
      BETTER_AUTH_SECRET = "Njg2ZDcwNTk2ZmNlODM1ZWNhYjY0MTZj";
      QSTASH_TOKEN = "not-needed";
      QSTASH_CURRENT_SIGNING_KEY = "not-needed";
      QSTASH_NEXT_SIGNING_KEY = "not-needed";
    };
    extraOptions = [
      "--cpus=2"
      "--memory=4g"
      "--memory-swap=4g"
      "--network=host"
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
