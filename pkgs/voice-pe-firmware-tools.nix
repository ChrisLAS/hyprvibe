{
  coreutils,
  esphome,
  fetchFromGitHub,
  gnugrep,
  gnupatch,
  gnused,
  writeShellApplication,
}:
let
  revision = "0579e7b9d8504264719c593474c85447253c9dc1";
  upstream = fetchFromGitHub {
    owner = "esphome";
    repo = "home-assistant-voice-pe";
    rev = revision;
    hash = "sha256-ku2jWlbsbx3+hAra04Mo/erfdTTGAWRkUCkzI1glHsA=";
  };
in
writeShellApplication {
  name = "voice-pe-firmware";
  runtimeInputs = [
    coreutils
    esphome
    gnugrep
    gnupatch
    gnused
  ];
  text = ''
    set -euo pipefail

    usage() {
      echo "Usage: voice-pe-firmware validate | build | flash [SERIAL_DEVICE]" >&2
      exit 2
    }

    action="''${1:-}"
    case "$action" in
      validate|build|flash) ;;
      *) usage ;;
    esac

    wifi_secret="$HOME/.config/secrets/jupiterproduction"
    api_secret="$HOME/.config/secrets/home-assistant-voice-pe-noise-key"
    for secret_file in "$wifi_secret" "$api_secret"; do
      if [ ! -r "$secret_file" ]; then
        echo "Required secret is not readable: $secret_file" >&2
        exit 1
      fi
    done

    state_root="''${XDG_STATE_HOME:-$HOME/.local/state}/voice-pe/firmware"
    mkdir -p "$state_root"
    chmod 700 "$state_root"
    work_dir="$(mktemp -d "$state_root/${revision}.XXXXXXXX")"
    chmod 700 "$work_dir"
    cp -R ${upstream}/. "$work_dir/"
    chmod -R u+w "$work_dir"
    patch --directory "$work_dir" --strip=1 < ${./voice-pe-firmware/push-to-talk.patch}
    sed -i \
      -e 's#/raw/dev/#/raw/${revision}/#g' \
      -e 's#ref: dev#ref: ${revision}#' \
      "$work_dir/home-assistant-voice.yaml"
    if grep -qE '/raw/dev/|ref: dev' "$work_dir/home-assistant-voice.yaml"; then
      echo "An unpinned upstream dev reference remains in the firmware configuration" >&2
      exit 1
    fi
    install -m 600 ${./voice-pe-firmware/home-assistant-voice-hermes.yaml} "$work_dir/home-assistant-voice-hermes.yaml"

    wifi_password="$(tr -d '\r\n' < "$wifi_secret")"
    api_encryption_key="$(tr -d '\r\n' < "$api_secret")"
    if [ -z "$wifi_password" ] || [ -z "$api_encryption_key" ]; then
      echo "A required secret file is empty" >&2
      exit 1
    fi
    umask 077
    {
      printf 'wifi_ssid: "JupiterProduction"\n'
      printf 'wifi_password: "%s"\n' "$wifi_password"
      printf 'api_encryption_key: "%s"\n' "$api_encryption_key"
    } > "$work_dir/secrets.yaml"
    unset wifi_password api_encryption_key

    config="$work_dir/home-assistant-voice-hermes.yaml"
    if [ "$action" = validate ]; then
      esphome config "$config" >/dev/null
      echo "ESPHome configuration is valid"
    elif [ "$action" = build ]; then
      esphome compile "$config"
    else
      serial_device="''${2:-/dev/ttyACM0}"
      if [ ! -c "$serial_device" ]; then
        echo "Serial device does not exist: $serial_device" >&2
        exit 1
      fi
      echo "Flashing explicit device $serial_device from pinned revision ${revision}"
      esphome run "$config" --device "$serial_device"
    fi

    echo "Private firmware work directory: $work_dir"
  '';
}
