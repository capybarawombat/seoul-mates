FROM debian:bookworm-slim

ARG GODOT_VERSION=4.7.2
ARG GODOT_SHA256=cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip \
    && rm -rf /var/lib/apt/lists/* \
    && curl -L --fail --silent --show-error -o /tmp/godot.zip \
       "https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" \
    && echo "${GODOT_SHA256}  /tmp/godot.zip" | sha256sum -c - \
    && unzip -j /tmp/godot.zip -d /tmp/godot-bin \
    && mv "/tmp/godot-bin/Godot_v${GODOT_VERSION}-stable_linux.x86_64" /usr/local/bin/godot \
    && rm -rf /tmp/godot.zip /tmp/godot-bin \
    && mkdir -p /app /srv/data /srv/config /srv/cache \
    && chown -R 10001:10001 /app /srv/data /srv/config /srv/cache

WORKDIR /app
COPY --chown=10001:10001 project.godot /app/
COPY --chown=10001:10001 scenes /app/scenes
COPY --chown=10001:10001 scripts /app/scripts
COPY --chown=10001:10001 data /app/data

ENV XDG_DATA_HOME=/srv/data XDG_CONFIG_HOME=/srv/config XDG_CACHE_HOME=/srv/cache
USER 10001:10001
EXPOSE 9090
VOLUME ["/srv/data"]
CMD ["/usr/local/bin/godot", "--headless", "--path", "/app", "--", "--server"]
