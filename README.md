# fe2-docker-arm64

ARM64-compatible Docker build for [FE2](https://github.com/alamos-gmbh/fe2-docker) by Alamos.

The official FE2 Docker image is currently published for `linux/amd64` only. This repository provides the tooling required to extract the architecture-independent FE2 application files from the official image and rebuild them into a native `linux/arm64` container.

## Status

Tested with:

- FE2 `2.41-STABLE`
- Linux `arm64`
- Amazon Corretto 25
- MongoDB 8
- Docker Compose

FE2 successfully starts natively on ARM64 and exposes its normal services on:

- `83/tcp`
- `64112/tcp`

No x86 emulation is required for the resulting FE2 container.

## Prebuilt image

The ARM64 image is available from GitHub Container Registry:

```bash
docker pull ghcr.io/reddevz/fe2-docker-arm64:latest
```

Or for a specific version:

```bash
docker pull ghcr.io/reddevz/fe2-docker-arm64:2.41-STABLE
```

The image is built for:

```text
linux/arm64
```

## How it works

The official Alamos image contains the FE2 Java application and its runtime resources.

This project:

1. Pulls the official `linux/amd64` FE2 image.
2. Extracts `/fe2.jar` and `/files`.
3. Builds a new ARM64 image based on Amazon Corretto 25.
4. Installs the required ARM64 runtime dependencies.
5. Runs a smoke test for obvious architecture or native-library failures.
6. Optionally publishes the result to GHCR.

The FE2 application itself does **not** need to be recompiled.

## Requirements

For building:

- Docker
- Docker Compose
- ARM64 Linux host recommended
- Git
- Access to the official `alamosgmbh/fe2` Docker image

The build has currently been tested natively on an ARM64 Linux VPS.

## Build manually

Clone the repository:

```bash
git clone git@github.com:RedDevz/fe2-docker-arm64.git
cd fe2-docker-arm64
```

### 1. Extract FE2

```bash
./scripts/extract.sh 2.41-STABLE
```

This pulls the official Alamos AMD64 image and extracts:

```text
build/
├── fe2.jar
└── files/
```

The extracted application files are ignored by Git and are not stored in this repository.

### 2. Build the ARM64 image

```bash
./scripts/build.sh 2.41-STABLE
```

This creates:

```text
fe2-arm64:2.41-STABLE
```

The build script also verifies that the resulting image is actually `linux/arm64` and checks the Java runtime.

### 3. Run the smoke test

```bash
./scripts/smoke-test.sh 2.41-STABLE
```

The smoke test checks for common architecture-related failures such as:

```text
Exec format error
wrong ELF
Illegal instruction
UnsatisfiedLinkError
UnsupportedClassVersionError
```

A successful smoke test does not replace a full FE2 installation test, but verifies that the ARM64 image can start without obvious architecture incompatibilities.

## Publish to GHCR

After building and testing:

```bash
./scripts/publish.sh 2.41-STABLE
```

This publishes:

```text
ghcr.io/reddevz/fe2-docker-arm64:2.41-STABLE
ghcr.io/reddevz/fe2-docker-arm64:latest
```

You must be logged into GHCR before publishing.

Example:

```bash
echo "$GHCR_TOKEN" | docker login ghcr.io -u reddevz --password-stdin
```

## Updating to a new FE2 release

When Alamos publishes a new FE2 Docker release, updating the ARM64 build should normally only require:

```bash
./scripts/extract.sh NEW_VERSION
./scripts/build.sh NEW_VERSION
./scripts/smoke-test.sh NEW_VERSION
./scripts/publish.sh NEW_VERSION
```

For example:

```bash
./scripts/extract.sh 2.42-STABLE
./scripts/build.sh 2.42-STABLE
./scripts/smoke-test.sh 2.42-STABLE
./scripts/publish.sh 2.42-STABLE
```

Each new FE2 version should be tested before publishing because upstream updates may introduce new native dependencies that do not support ARM64.

## Docker Compose

A Compose example is included as:

```text
compose.example.yml
```

Use the GHCR image in the FE2 application service:

```yaml
services:
  fe2_app:
    image: ghcr.io/reddevz/fe2-docker-arm64:latest
```

FE2 still requires its normal configuration, MongoDB, activation credentials and persistent volumes as described by Alamos.

Typical persistent paths include:

```text
/Config
/Logs
```

A stable machine ID may also be required by FE2:

```yaml
volumes:
  - /var/lib/dbus/machine-id:/var/lib/dbus/machine-id:ro
```

## Architecture notes

FE2 `2.41-STABLE` requires Java class file version `69`, which corresponds to Java 25.

The ARM64 image therefore uses:

```dockerfile
FROM amazoncorretto:25-alpine
```

Several dependencies bundled inside FE2 already contain ARM64-native binaries, including components for:

- JNA
- gRPC / Netty
- Netty epoll
- jSerialComm
- Yggdrasil / Unleash

The container additionally installs the ARM64 Alpine `libsodium` package.

## Disclaimer

This project is **not affiliated with or endorsed by Alamos GmbH**.

FE2 itself remains proprietary software owned by Alamos GmbH.

This repository does not contain FE2 source code, licence credentials or user configuration.

The build scripts obtain FE2 application files from the official Alamos Docker image.

Before redistributing prebuilt images publicly, make sure that doing so is permitted by the applicable FE2 licence and terms.

## Credits

FE2 and the official Docker deployment:

- Alamos GmbH
- `alamos-gmbh/fe2-docker`

ARM64 compatibility tooling and packaging:

- RedDevz
