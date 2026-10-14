# Assessment candidate using upstream's supported npm installation. No overrides.
# Do not promote unless its exact image passes the documented security gates.
FROM node:24-bookworm-slim@sha256:d6aa754f16b3197301076f047b5def2f02ea1dbbc2ca920407d46d7ec7f87b20 AS dependencies
WORKDIR /opt/n8n
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --no-audit --no-fund && npm cache clean --force
FROM node:24-bookworm-slim@sha256:d6aa754f16b3197301076f047b5def2f02ea1dbbc2ca920407d46d7ec7f87b20
ARG GIT_SHA
LABEL org.opencontainers.image.revision=$GIT_SHA
RUN apt-get update && apt-get upgrade -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*
COPY --from=dependencies /opt/n8n /opt/n8n
ENV PATH="/opt/n8n/node_modules/.bin:$PATH"
USER node
WORKDIR /home/node
EXPOSE 5678
ENTRYPOINT ["n8n"]
CMD ["start"]
