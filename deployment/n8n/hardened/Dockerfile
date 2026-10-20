FROM n8nio/n8n:2.44.4@sha256:c72fa9f1bd9b59626deeb284824c0495625c3f6d894d395d27e241bf192d9900 AS upstream

FROM node:26-alpine3.24@sha256:6f08a523443ddedf52941874c203475b0ad503e859ad70cb26ab8be9a517dbd5 AS patched
WORKDIR /opt/security-updates
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts --no-audit --no-fund
COPY --from=upstream /usr/local/lib/node_modules/n8n /usr/local/lib/node_modules/n8n
COPY patch-runtime.mjs /opt/volitex/security/patch-runtime.mjs
RUN node /opt/volitex/security/patch-runtime.mjs

FROM node:26-alpine3.24@sha256:6f08a523443ddedf52941874c203475b0ad503e859ad70cb26ab8be9a517dbd5
ARG GIT_SHA
LABEL org.opencontainers.image.title="Volitex AI Inbox automation runtime" \
      org.opencontainers.image.revision=$GIT_SHA
ENV NODE_ENV=production
RUN apk add --no-cache zlib=1.3.2-r1
COPY --from=patched /usr/local/lib/node_modules/n8n /usr/local/lib/node_modules/n8n
COPY --from=patched /opt/security-updates/node_modules /opt/security-updates/node_modules
COPY --from=patched /opt/volitex/security/manifest.json /opt/volitex/security/manifest.json
COPY verify-runtime.mjs /opt/volitex/security/verify-runtime.mjs
RUN rm -rf /usr/local/lib/node_modules/npm /opt/yarn* \
    && rm -f /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/yarn /usr/local/bin/yarnpkg \
    && ln -s /usr/local/lib/node_modules/n8n/bin/n8n /usr/local/bin/n8n \
    && printf '%s' "$GIT_SHA" > /opt/volitex/security/source-sha \
    && node /opt/volitex/security/verify-runtime.mjs
USER node
WORKDIR /home/node
EXPOSE 5678
ENTRYPOINT ["node", "/usr/local/lib/node_modules/n8n/bin/n8n"]
CMD ["start"]
