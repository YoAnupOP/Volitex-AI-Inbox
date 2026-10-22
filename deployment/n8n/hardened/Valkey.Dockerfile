FROM valkey/valkey:8-alpine@sha256:081c2f5cb575efc901aa80ff9cdbd1ec6a301682fd35e1ebb4b0990a4a4a8507
ARG GIT_SHA
LABEL org.opencontainers.image.title="Volitex AI Inbox n8n queue" \
      org.opencontainers.image.revision=$GIT_SHA
RUN apk add --no-cache zlib=1.3.2-r1 musl=1.2.6-r3 musl-utils=1.2.6-r3 \
    && mkdir -p /opt/volitex \
    && printf '%s' "$GIT_SHA" > /opt/volitex/valkey-source-sha
