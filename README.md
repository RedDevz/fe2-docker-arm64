# fe2-docker-arm64

Native ARM64 Docker packaging for [FE2](https://github.com/alamos-gmbh/fe2-docker) by Alamos GmbH.

The official FE2 Docker image is currently published for `linux/amd64`. This project provides tooling to extract the FE2 application files from the official image and package them into a native `linux/arm64` image without x86 emulation.

> [!IMPORTANT]
> FE2 is proprietary software owned by Alamos GmbH. This project is not affiliated with or endorsed by Alamos GmbH. Publishing the prebuilt ARM64 images in this repository has been permitted by Alamos GmbH. A valid FE2 licence/activation is still required to use FE2.

## Status

Currently tested with:

- FE2 `2.41-STABLE`
- Linux `arm64`
- Amazon Corretto 25
- MongoDB 8
- Docker / Docker Compose

The resulting FE2 container runs natively on ARM64 and exposes the normal FE2 services on:

- `83/tcp`
- `64112/tcp`

No QEMU or other x86 emulation is required for the resulting FE2 container.

## Prebuilt image

Prebuilt ARM64 images are published to GitHub Container Registry.

Latest:

```bash
docker pull ghcr.io/reddevz/fe2-docker-arm64:latest
```

Specific FE2 version:

```bash
docker pull ghcr.io/reddevz/fe2-docker-arm64:2.41-STABLE
```

Image platform:

```text
linux/arm64
```

## How it works

The official Alamos image contains the FE2 Java application and its runtime resources. This project does not rebuild or modify FE2 source code.

The build process:

1. Pulls the official `linux/amd64` FE2 image.
2. Extracts `/fe2.jar` and `/files` from that image.
3. Builds a new ARM64 image based on Amazon Corretto 25.
4. Installs the ARM64-native runtime dependencies required by FE2.
5. Verifies the resulting image architecture and Java runtime.
6. Runs a startup smoke test for architecture and runtime failures.
7. Optionally publishes the tested image to GHCR.

The extracted FE2 files are stored only in the local `build/` directory and are ignored by Git.

## Quick start

A Docker Compose example is included as [`compose.example.yml`](./compose.example.yml).

At minimum, the FE2 service can use the published image like this:

```yaml
services:
  fe2_app:
    image: ghcr.io/reddevz/fe2-docker-arm64:2.41-STABLE
```

FE2 still requires its normal configuration, MongoDB, persistent storage and activation credentials.

Typical persistent mounts include:

```yaml
volumes:
  - ./data/fe2/config:/Config
  - ./data/fe2/logs:/Logs
```

A stable machine ID may also be required:

```yaml
volumes:
  - /var/lib/dbus/machine-id:/var/lib/dbus/machine-id:ro
```

See the official [Alamos FE2 Docker repository](https://github.com/alamos-gmbh/fe2-docker) for the upstream FE2 Docker configuration and requirements.

## Building locally

### Requirements

- Docker
- Docker Compose
- Git
- Access to the official `alamosgmbh/fe2` image
- ARM64 Linux host recommended

The build process has been tested natively on an ARM64 Linux VPS.

### Clone the repository

```bash
git clone https://github.com/RedDevz/fe2-docker-arm64.git
cd fe2-docker-arm64
```

### 1. Extract FE2

```bash
./scripts/extract.sh 2.41-STABLE
```

This pulls the official AMD64 image and extracts:

```text
build/
├── fe2.jar
└── files/
```

These files are not committed to this repository.

### 2. Build the ARM64 image

```bash
./scripts/build.sh 2.41-STABLE
```

This creates:

```text
fe2-arm64:2.41-STABLE
```

The build script also verifies that the resulting image is `linux/arm64` and checks the Java runtime.

### 3. Run the smoke test

```bash
./scripts/smoke-test.sh 2.41-STABLE
```

The smoke test verifies, among other things:

- image architecture is `arm64`
- the expected FE2 `ENTRYPOINT` is present
- Java starts successfully
- the FE2 container stays running during initialization
- no obvious ARM/native-library failures appear in the logs
- no `UnsupportedClassVersionError` occurs

It specifically looks for failures such as:

```text
exec format error
wrong ELF
illegal instruction
UnsatisfiedLinkError
UnsupportedClassVersionError
```

A successful smoke test does not replace a complete FE2 installation test, but it catches common packaging and architecture problems before publishing.

## Publishing to GHCR

After building and testing:

```bash
./scripts/publish.sh 2.41-STABLE
```

This publishes both:

```text
ghcr.io/reddevz/fe2-docker-arm64:2.41-STABLE
ghcr.io/reddevz/fe2-docker-arm64:latest
```

You must be logged into GitHub Container Registry before publishing.

Example:

```bash
echo "$GHCR_TOKEN" | docker login ghcr.io -u reddevz --password-stdin
```

## Updating for a new FE2 release

The complete update workflow can be run with:

```bash
./scripts/update.sh NEW_VERSION
```

For example:

```bash
./scripts/update.sh 2.42-STABLE
```

The update script performs the full pipeline:

```text
extract -> build -> smoke test -> publish
```

Each new FE2 release should still be tested before being used in production because upstream changes may introduce new native dependencies or other ARM64 compatibility issues.

The individual steps can also be run manually:

```bash
./scripts/extract.sh NEW_VERSION
./scripts/build.sh NEW_VERSION
./scripts/smoke-test.sh NEW_VERSION
./scripts/publish.sh NEW_VERSION
```

## Repository structure

```text
.
├── Dockerfile
├── README.md
├── compose.example.yml
├── scripts/
│   ├── build.sh
│   ├── extract.sh
│   ├── publish.sh
│   ├── smoke-test.sh
│   └── update.sh
└── build/              # generated locally, ignored by Git
```

## Architecture notes

FE2 `2.41-STABLE` uses Java class file version `69`, which corresponds to Java 25. The ARM64 image therefore uses:

```dockerfile
FROM amazoncorretto:25-alpine
```

Several dependencies bundled with FE2 already contain ARM64-native binaries, including components for:

- JNA
- gRPC / Netty
- Netty epoll
- jSerialComm
- Yggdrasil / Unleash

The image additionally installs the ARM64 Alpine `libsodium` package together with the other runtime packages required by FE2.

The image starts FE2 using:

```dockerfile
ENTRYPOINT ["java", "-jar", "/fe2.jar", "server"]
```

## Production use

For production deployments, prefer a versioned image tag instead of `latest`:

```yaml
image: ghcr.io/reddevz/fe2-docker-arm64:2.41-STABLE
```

This prevents a later publish of `latest` from changing the image selected for an existing production deployment.

Persistent FE2 and MongoDB data should be stored outside the container and backed up independently.

## Disclaimer and permissions

This project is **not affiliated with or endorsed by Alamos GmbH**.

FE2 itself remains proprietary software owned by Alamos GmbH. This repository does not contain the FE2 source code, licence credentials or user configuration.

The build scripts obtain FE2 application files from the official Alamos Docker image and repackage them for ARM64.

**Alamos GmbH has granted permission for the resulting prebuilt ARM64 FE2 images to be published.** This permission does not make FE2 open-source and does not replace the normal FE2 licence or activation requirements.

The code and tooling in this repository are separate from the proprietary FE2 application contained in the built image.

## Credits

FE2 and the official Docker deployment:

- [Alamos GmbH](https://www.alamos-gmbh.com/)
- [`alamos-gmbh/fe2-docker`](https://github.com/alamos-gmbh/fe2-docker)

ARM64 compatibility tooling and packaging:

- [RedDevz](https://github.com/RedDevz)