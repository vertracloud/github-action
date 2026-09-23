#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/fixture" "$tmp/project"

cat >"$tmp/fixture/vertra" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$PWD" "$*" >"$LOG_FILE"
SH
chmod +x "$tmp/fixture/vertra"
tar -czf "$tmp/fixture/vertra_v1.2.3_linux_amd64.tar.gz" -C "$tmp/fixture" vertra
cp "$tmp/fixture/vertra_v1.2.3_linux_amd64.tar.gz" "$tmp/fixture/vertra_v1.2.3_linux_arm64.tar.gz"
(cd "$tmp/fixture" && shasum -a 256 vertra_v1.2.3_linux_*.tar.gz >checksums.txt)

cat >"$tmp/bin/curl" <<'SH'
#!/usr/bin/env bash
while (($#)); do
  if [[ "$1" == --output ]]; then output="$2"; shift 2; else url="$1"; shift; fi
done
cp "$FIXTURE/$(basename "$url")" "$output"
SH
chmod +x "$tmp/bin/curl"

export PATH="$tmp/bin:$PATH" FIXTURE="$tmp/fixture" LOG_FILE="$tmp/cli.log"
export VERTRA_API_KEY=test-key VERTRA_APP_ID=app-123 VERTRA_CLI_VERSION=v1.2.3 VERTRA_PROJECT_PATH="$tmp/project"

VERTRA_RESTART=true bash "$root/deploy.sh"
[[ "$(cat "$tmp/cli.log")" == "$tmp/project"$'\n''deploy app-123 --json --restart' ]]
VERTRA_RESTART=false RUNNER_ARCH=ARM64 bash "$root/deploy.sh"
[[ "$(cat "$tmp/cli.log")" == "$tmp/project"$'\n''deploy app-123 --json' ]]

if VERTRA_RESTART=maybe bash "$root/deploy.sh" >/dev/null 2>&1; then
  echo "invalid restart was accepted" >&2
  exit 1
fi
if VERTRA_CLI_VERSION=latest bash "$root/deploy.sh" >/dev/null 2>&1; then
  echo "un-pinned version was accepted" >&2
  exit 1
fi
if RUNNER_OS=Windows bash "$root/deploy.sh" >/dev/null 2>&1; then
  echo "windows runner was accepted" >&2
  exit 1
fi
