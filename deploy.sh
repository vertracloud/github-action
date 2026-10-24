#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${VERTRA_API_KEY:-}" ]]; then
  echo "::error::The 'api-key' input is required."
  exit 1
fi
echo "::add-mask::$VERTRA_API_KEY"
if [[ -n "${VERTRA_APP_ID:-}" && -n "${VERTRA_IMAGE_ID:-}" ]]; then
  echo "::error::Use either 'app-id' or 'image-id', not both."
  exit 1
fi
if [[ -z "${VERTRA_APP_ID:-}" && -z "${VERTRA_IMAGE_ID:-}" ]]; then
  echo "::error::One of the 'app-id' or 'image-id' inputs is required."
  exit 1
fi
if [[ ! "${VERTRA_CLI_VERSION:-}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([-.][A-Za-z0-9.-]+)?$ ]]; then
  echo "::error::The 'cli-version' input must be a release tag like v0.1.0."
  exit 1
fi

case "${VERTRA_RESTART:-true}" in
  true) restart=true ;;
  false) restart=false ;;
  *)
    echo "::error::The 'restart' input must be 'true' or 'false'."
    exit 1
    ;;
esac

case "${RUNNER_OS:-Linux}" in
  Linux) os=linux ;;
  macOS) os=darwin ;;
  *)
    echo "::error::Unsupported runner OS: ${RUNNER_OS}. Use a Linux or macOS runner."
    exit 1
    ;;
esac
case "${RUNNER_ARCH:-X64}" in
  X64) arch=amd64 ;;
  ARM64) arch=arm64 ;;
  *)
    echo "::error::Unsupported runner architecture: ${RUNNER_ARCH}."
    exit 1
    ;;
esac

asset="vertra_${VERTRA_CLI_VERSION}_${os}_${arch}.tar.gz"
release="https://github.com/vertracloud/cli/releases/download/${VERTRA_CLI_VERSION}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
curl --fail --silent --show-error --location "$release/$asset" --output "$tmp_dir/$asset"
curl --fail --silent --show-error --location "$release/checksums.txt" --output "$tmp_dir/checksums.txt"

expected="$(awk -v asset="$asset" '$2 == asset { print $1 }' "$tmp_dir/checksums.txt")"
if [[ ! "$expected" =~ ^[[:xdigit:]]{64}$ ]]; then
  echo "::error::The release has no valid SHA-256 checksum for $asset."
  exit 1
fi
printf '%s  %s\n' "$expected" "$tmp_dir/$asset" | shasum -a 256 --check --status || {
  echo "::error::The CLI checksum does not match."
  exit 1
}

tar -xzf "$tmp_dir/$asset" -C "$tmp_dir"
if [[ ! -f "$tmp_dir/vertra" ]]; then
  echo "::error::The release archive does not contain the vertra binary."
  exit 1
fi
chmod +x "$tmp_dir/vertra"
if [[ -n "${VERTRA_IMAGE_ID:-}" ]]; then
  # Docker image: the folder is packed (honoring .dockerignore, never sending .env*)
  # and the image is rebuilt. Apps never restart on their own, so 'restart' does not apply.
  "$tmp_dir/vertra" image rebuild "$VERTRA_IMAGE_ID" --context "${VERTRA_PROJECT_PATH:-.}" --json
  exit 0
fi
cd "${VERTRA_PROJECT_PATH:-.}"
if [[ "$restart" == true ]]; then
  "$tmp_dir/vertra" deploy "$VERTRA_APP_ID" --json --restart
else
  "$tmp_dir/vertra" deploy "$VERTRA_APP_ID" --json
fi
