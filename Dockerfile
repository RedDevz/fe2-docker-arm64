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

COPY build/fe2.jar /fe2.jar
COPY build/files /files

WORKDIR /

EXPOSE 83
EXPOSE 64112
