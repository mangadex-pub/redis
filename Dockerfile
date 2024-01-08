ARG REDIS_VERSION="7.2"
FROM bitnami/redis:${REDIS_VERSION} as redis-upstream

FROM redis-upstream as builder

USER root
RUN apt update && \
    apt install -y \
      build-essential \
      curl \
      git \
      tar \
      wget

WORKDIR /tmp
ENTRYPOINT /bin/bash

FROM builder as redisjson
ARG REDISJSON_VERSION="v2.6.8"
ENV REDISJSON_VERSION="${REDISJSON_VERSION}"

# Install Rust toolchain
ENV PATH "$HOME/.cargo/bin:$PATH"
RUN curl -sSf "https://sh.rustup.rs" | sh -s -- -y
RUN cargo --version && rustc --version

RUN mkdir -pv /build && \
    git clone --recursive --depth=1 --branch "${REDISJSON_VERSION}" "https://github.com/RedisJSON/RedisJSON.git" "/build/redisjson"
WORKDIR /build/redisjson

RUN make setup
RUN make build NIGHTLY=0 DEBUG=0 VG=0 && \
    ldd "/build/redisjson/bin/linux-x64-release/rejson.so"

FROM builder as redisearch
ARG REDISEARCH_VERSION="v2.8.10"
ENV REDISEARCH_VERSION="${REDISEARCH_VERSION}"

RUN mkdir -pv /build && \
    git clone --recursive --depth=1 --branch "${REDISEARCH_VERSION}" "https://github.com/RediSearch/RediSearch.git" "/build/redisearch"
WORKDIR /build/redisearch

RUN make setup
RUN make build COORD=oss MT=1 LITE=0 DEBUG=0 TESTS=0 VG=0 SLOW=0 && \
    ldd "/build/redisearch/bin/linux-x64-release/coord-oss/module-oss.so"
RUN make build MT=1 LITE=0 DEBUG=0 TESTS=0 VG=0 SLOW=0 && \
    ldd "/build/redisearch/bin/linux-x64-release/search/redisearch.so"

FROM redis-upstream

COPY --from=redisjson  /build/redisjson/bin/linux-x64-release/rejson.so                /opt/mangadex/redis-modules/rejson.so
COPY --from=redisearch /build/redisearch/bin/linux-x64-release/search/redisearch.so    /opt/mangadex/redis-modules/redisearch.so
COPY --from=redisearch /build/redisearch/bin/linux-x64-release/coord-oss/module-oss.so /opt/mangadex/redis-modules/redisearch-coord.so
