#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-}"

if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <FE2 image tag>"
  echo "Example: $0 2.41-STABLE"
  exit 1
fi

BUILD_DIR="$(pwd)/build"
IMAGE="fe2-arm64:${VERSION}"

if [[ ! -f "$BUILD_DIR/fe2.jar" ]]; then
  echo "Error: $BUILD_DIR/fe2.jar not found."
  echo "Run ./scripts/extract.sh $VERSION first."
  exit 1
fi

if [[ ! -d "$BUILD_DIR/files" ]]; then
  echo "Error: $BUILD_DIR/files not found."
  echo "Run ./scripts/extract.sh $VERSION first."
  exit 1
fi

echo "==> Building $IMAGE"

docker build \
  --platform linux/arm64 \
  --build-arg BUILD_DIR=build \
  -t "$IMAGE" \
  .

echo
echo "==> Build finished"

docker image inspect "$IMAGE" \
  --format 'Image={{.RepoTags}} Architecture={{.Architecture}} OS={{.Os}}'

echo
echo "==> Java check"

docker run --rm \
  --entrypoint sh \
  "$IMAGE" \
  -c 'uname -m && java -version'
