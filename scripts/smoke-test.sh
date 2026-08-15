#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-}"

if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <FE2 image tag>"
  echo "Example: $0 2.41-STABLE"
  exit 1
fi

IMAGE="fe2-arm64:${VERSION}"
CONTAINER="fe2-arm64-smoke"

cleanup() {
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "==> Checking image architecture"

ARCH="$(docker image inspect "$IMAGE" --format '{{.Architecture}}')"

if [[ "$ARCH" != "arm64" ]]; then
  echo "ERROR: Expected arm64, got $ARCH"
  exit 1
fi

echo "Architecture: $ARCH"

echo
echo "==> Checking image ENTRYPOINT"

ENTRYPOINT="$(docker image inspect "$IMAGE" --format '{{json .Config.Entrypoint}}')"

if [[ "$ENTRYPOINT" != '["java","-jar","/fe2.jar","server"]' ]]; then
  echo "ERROR: Invalid ENTRYPOINT: $ENTRYPOINT"
  exit 1
fi

echo "ENTRYPOINT: $ENTRYPOINT"

echo
echo "==> Checking Java"

docker run --rm \
  --entrypoint sh \
  "$IMAGE" \
  -c 'uname -m && java -version'

echo
echo "==> Starting FE2 smoke test"

docker rm -f "$CONTAINER" >/dev/null 2>&1 || true

docker run -d \
  --name "$CONTAINER" \
  "$IMAGE" >/dev/null

echo "Waiting for FE2 initialization..."
sleep 45

STATUS="$(docker inspect "$CONTAINER" --format '{{.State.Status}}')"
EXIT_CODE="$(docker inspect "$CONTAINER" --format '{{.State.ExitCode}}')"

echo "Container status: $STATUS"
echo "Exit code: $EXIT_CODE"

if [[ "$STATUS" == "exited" && "$EXIT_CODE" == "0" ]]; then
  echo
  echo "ERROR: Container exited cleanly instead of staying running."
  echo "This usually means the image ENTRYPOINT/CMD is wrong or missing."
  exit 1
fi

LOGS="$(docker logs "$CONTAINER" 2>&1 || true)"

echo
echo "==> FE2 log output"
echo "$LOGS"

echo
echo "==> Checking for architecture/runtime failures"

if echo "$LOGS" | grep -Eqi \
  'exec format error|wrong ELF|illegal instruction|UnsatisfiedLinkError|cannot load.*shared|no suitable image found'
then
  echo
  echo "ERROR: Possible ARM/native-library failure detected."
  exit 1
fi

if echo "$LOGS" | grep -q \
  'UnsupportedClassVersionError'
then
  echo
  echo "ERROR: Wrong Java runtime version."
  exit 1
fi

echo
echo "Smoke test passed."
echo "No fatal ARM64/runtime compatibility errors detected."
