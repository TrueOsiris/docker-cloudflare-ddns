ARG S6_ARCH
FROM alpine:latest

ARG QEMU_ARCH
ENV QEMU_ARCH=${QEMU_ARCH:-x86_64} S6_KEEP_ENV=1

RUN set -x && apk add --no-cache curl coreutils tzdata shadow bind-tools jq file \
  && case "${QEMU_ARCH}" in \
    x86_64) S6_ARCH='x86_64';; \
    arm) S6_ARCH='armhf';; \
    aarch64) S6_ARCH='aarch64';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  && echo "downloading qemu-${QEMU_ARCH:-x86_64}-static.tar.gz" \
  && curl -L -s https://github.com/multiarch/qemu-user-static/releases/download/v7.2.0-1/qemu-${QEMU_ARCH:-x86_64}-static.tar.gz -o /tmp/qemu-static.tar.gz \
  && tar xvzf /tmp/qemu-static.tar.gz -C /usr/bin \
  && rm /tmp/qemu-static.tar.gz \
  && echo "downloading s6-overlay-${S6_ARCH}.tar.xz" \
  && curl -L -s https://github.com/just-containers/s6-overlay/releases/download/v3.2.1.0/s6-overlay-${S6_ARCH}.tar.xz -o /tmp/s6-overlay.tar.xz \
  && file /tmp/s6-overlay.tar.xz \
  && tar xJf /tmp/s6-overlay.tar.xz -C / \
  && rm /tmp/s6-overlay.tar.xz \
  && groupmod -g 911 users && \
  useradd -u 911 -U -d /config -s /bin/false abc && \
  usermod -G users abc && \
  mkdir -p /app /config /defaults && \
  apk del --no-cache curl \
  apk del --purge \
  rm -rf /tmp/*

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 CF_API=https://api.cloudflare.com/client/v4 RRTYPE=A CRON="*/5	*	*	*	*"

COPY root /

