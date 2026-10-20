FROM postgres:17-alpine@sha256:b0f9560a2de083e2cc7382e75f808c7381a32852a7ec49117deedb300e552b24
ARG GIT_SHA
LABEL org.opencontainers.image.title="Volitex AI Inbox n8n PostgreSQL" \
      org.opencontainers.image.revision=$GIT_SHA
# Use Alpine's C helper for the entrypoint's fixed postgres-user exec, removing
# the old Go runtime embedded in vendor gosu. No database binary is replaced.
RUN apk add --no-cache su-exec=0.3-r0 zlib=1.3.2-r1 \
    && grep -Fq 'exec gosu postgres' /usr/local/bin/docker-entrypoint.sh \
    && sed -i 's/exec gosu postgres/exec su-exec postgres/' /usr/local/bin/docker-entrypoint.sh \
    && rm /usr/local/bin/gosu \
    && ! grep -q gosu /usr/local/bin/docker-entrypoint.sh \
    && mkdir -p /opt/volitex \
    && printf '%s' "$GIT_SHA" > /opt/volitex/postgres-source-sha \
    && test "$(su-exec postgres id -u)" = 70
