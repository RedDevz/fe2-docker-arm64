FROM amazoncorretto:25-alpine

RUN apk add --no-cache \
    nano \
    bind-tools \
    htop \
    curl \
    msttcorefonts-installer \
    fontconfig \
    cups-client \
    libsodium

RUN update-ms-fonts

COPY fe2.jar /fe2.jar
COPY files /files

WORKDIR /

EXPOSE 83
EXPOSE 64112
