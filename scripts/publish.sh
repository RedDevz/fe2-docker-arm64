#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-}"

if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <FE2 image tag>"
  echo "Example: $0 2.41-STABLE"
  exit 1
fi

GITHUB_USER="reddevz"
PACKAGE="fe2-docker-arm64"

LOCAL_IMAGE="fe2-arm64:${VERSION}"
REMOTE_IMAGE="ghcr.io/${GITHUB_USER}/${PACKAGE}:${VERSION}"
LATEST_IMAGE="ghcr.io/${GITHUB_USER}/${PACKAGE}:latest"

echo "==> Checking local image"

docker image inspect "$LOCAL_IMAGE" >/dev/null

echo "==> Tagging"

docker tag "$LOCAL_IMAGE" "$REMOTE_IMAGE"
docker tag "$LOCAL_IMAGE" "$LATEST_IMAGE"

echo "==> Publishing $REMOTE_IMAGE"
docker push "$REMOTE_IMAGE"

echo "==> Publishing $LATEST_IMAGE"
docker push "$LATEST_IMAGE"

echo
echo "Published:"
echo "  $REMOTE_IMAGE"
echo "  $LATEST_IMAGE"
