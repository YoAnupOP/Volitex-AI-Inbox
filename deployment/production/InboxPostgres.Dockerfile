FROM postgres:16-alpine@sha256:deb28ee471183cb0c303113dac9b2433c51eeeeb678def7af9a9ec5820367815 AS builder
ADD --checksum=sha256:cac0b10c360f05b2d521200105ba3697e773d4cd3731f5a915a7e37ebe0bea85 https://codeload.github.com/pgvector/pgvector/tar.gz/refs/tags/v0.8.7 /tmp/pgvector.tar.gz
RUN apk add --no-cache build-base \
    && tar -xzf /tmp/pgvector.tar.gz -C /tmp \
    && make -C /tmp/pgvector-0.8.7 OPTFLAGS="" with_llvm=no \
    && make -C /tmp/pgvector-0.8.7 OPTFLAGS="" with_llvm=no install

FROM postgres:16-alpine@sha256:deb28ee471183cb0c303113dac9b2433c51eeeeb678def7af9a9ec5820367815
ARG GIT_SHA
LABEL org.opencontainers.image.title="Volitex AI Inbox PostgreSQL with pgvector" \
      org.opencontainers.image.revision=$GIT_SHA
RUN apk add --no-cache su-exec=0.3-r0 zlib=1.3.2-r1 musl=1.2.6-r3 musl-utils=1.2.6-r3 \
    && grep -Fq 'exec gosu postgres' /usr/local/bin/docker-entrypoint.sh \
    && sed -i 's/exec gosu postgres/exec su-exec postgres/' /usr/local/bin/docker-entrypoint.sh \
    && rm /usr/local/bin/gosu \
    && ! grep -q gosu /usr/local/bin/docker-entrypoint.sh \
    && mkdir -p /opt/volitex \
    && printf '%s' "$GIT_SHA" > /opt/volitex/inbox-postgres-source-sha \
    && test "$(su-exec postgres id -u)" = 70
COPY --from=builder /usr/local/lib/postgresql/vector.so /usr/local/lib/postgresql/vector.so
COPY --from=builder /usr/local/share/postgresql/extension/vector* /usr/local/share/postgresql/extension/
CMD ["postgres", "-c", "shared_preload_libraries=pg_stat_statements"]
