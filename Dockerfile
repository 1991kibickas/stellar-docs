FROM ubuntu:24.04 AS build

LABEL maintainer="SDF Ops Team <ops@stellar.org>"

RUN mkdir -p /app
WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive
ENV INLINE_RUNTIME_CHUNK=false
RUN apt-get update && apt-get install --no-install-recommends -y gpg curl git make ca-certificates apt-transport-https && \
    curl -sSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key|gpg --dearmor >/etc/apt/trusted.gpg.d/nodesource-key.gpg && \
    echo "deb https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg |gpg --dearmor >/etc/apt/trusted.gpg.d/yarnpkg.gpg && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y nodejs yarn && apt-get clean

COPY . /app/
ARG CROWDIN_PERSONAL_TOKEN
ARG BUILD_TRANSLATIONS="False"

RUN yarn install
RUN yarn rpcspec:build
RUN yarn stellar-cli:build

ENV NODE_OPTIONS="--max-old-space-size=4096"
RUN if [ "$BUILD_TRANSLATIONS" = "True" ]; then \
    CROWDIN_PERSONAL_TOKEN=${CROWDIN_PERSONAL_TOKEN} yarn build:production; \
  else \
    # In the preview build, we only want to build for English. Much quicker
    yarn build; \
  fi

FROM nginx:1.27

COPY --from=build /app/build/ /usr/share/nginx/html/
COPY nginx /etc/nginx/
