FROM alpine:latest

ARG QEMU_ARCH
ENV QEMU_ARCH=${QEMU_ARCH:-x86_64}

# Install dependencies
RUN set -x \
  && apk add --no-cache jq curl bind-tools shadow tzdata coreutils busybox-suid cronie \
  && groupmod -g 911 users \
  && useradd -u 911 -U -d /config -s /bin/false abc \
  && mkdir -p /app /config /defaults

# Optional: QEMU if cross-compiling
RUN curl -L -s https://github.com/multiarch/qemu-user-static/releases/download/v7.2.0-1/qemu-${QEMU_ARCH}-static.tar.gz -o /tmp/qemu.tar.gz \
  && tar -xvzf /tmp/qemu.tar.gz -C /usr/bin \
  && rm /tmp/qemu.tar.gz

# Environment
ENV CF_API=https://api.cloudflare.com/client/v4 \
    RRTYPE=A \
    CRON="*/5 * * * *"

# Copy your script/files into the image
COPY root/ /
RUN chmod +x /app/* \
 && ln -s /app/cloudflare.sh /usr/local/bin/cloudflare.sh \
 && echo "*/5 * * * * abc /usr/local/bin/cloudflare.sh >> /var/log/cron.log 2>&1" > /etc/crontabs/abc \
 && touch /var/log/cron.log \
 && chown abc:users /var/log/cron.log \
 && chown abc:users /etc/crontabs/abc
CMD ["/bin/sh", "-c", "/usr/sbin/crond -f && tail -F /var/log/cron.log"]



