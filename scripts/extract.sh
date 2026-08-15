#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-}"

if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <FE2 image tag>"
  echo "Example: $0 2.41-STABLE"
  exit 1
fi

IMAGE="alamosgmbh/fe2:${VERSION}"
BUILD_DIR="$(pwd)/build"
CONTAINER_NAME="fe2-docker-arm64-extract"

echo "==> Preparing build directory"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Pulling official AMD64 image: $IMAGE"
docker pull --platform linux/amd64 "$IMAGE"

echo "==> Creating temporary container"
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

docker create \
  --platform linux/amd64 \
  --name "$CONTAINER_NAME" \
  "$IMAGE" >/dev/null

cleanup() {
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "==> Extracting FE2.jar"
docker cp "$CONTAINER_NAME:/fe2.jar" "$BUILD_DIR/fe2.jar"

echo "==> Extracting /files"
docker cp "$CONTAINER_NAME:/files" "$BUILD_DIR/files"

echo
echo "Done."
echo "Extracted:"
du -sh "$BUILD_DIR/fe2.jar" "$BUILD_DIR/files"
