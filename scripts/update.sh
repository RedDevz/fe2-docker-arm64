#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-}"

if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <FE2 image tag>"
  echo "Example: $0 2.42-STABLE"
  exit 1
fi

echo "==> FE2 ARM64 update: $VERSION"
echo

echo "==> Step 1/4: Extracting official FE2 image"
./scripts/extract.sh "$VERSION"

echo
echo "==> Step 2/4: Building ARM64 image"
./scripts/build.sh "$VERSION"

echo
echo "==> Step 3/4: Running smoke test"
./scripts/smoke-test.sh "$VERSION"

echo
echo "==> Step 4/4: Publishing to GHCR"
./scripts/publish.sh "$VERSION"

echo
echo "========================================"
echo "FE2 ARM64 $VERSION successfully published"
echo
echo "ghcr.io/reddevz/fe2-docker-arm64:$VERSION"
echo "ghcr.io/reddevz/fe2-docker-arm64:latest"
echo "========================================"
