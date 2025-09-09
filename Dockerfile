FROM debian:bookworm-slim

ENV TELEPORT_VERSION=17.7.1

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl https://cdn.teleport.dev/install.sh | bash -s ${TELEPORT_VERSION} oss

RUN mkdir -p /var/lib/teleport \
    /etc/teleport \
    /var/log/teleport

RUN groupadd -r teleport && useradd --no-log-init -r -g teleport -d /var/lib/teleport -s /sbin/nologin teleport
RUN chown -R teleport:teleport /var/lib/teleport /etc/teleport /var/log/teleport

USER teleport

ENTRYPOINT ["/usr/local/bin/teleport"]
CMD ["start", "-c", "/etc/teleport/teleport.yaml"]