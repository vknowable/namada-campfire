from rust:1.70 AS builder
WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    clang-tools-11 \
    git \
    libssl-dev \
    pkg-config \
    protobuf-compiler \
    libudev-dev \
    && apt-get clean

# optionally also compile the wasm files
ARG BUILD_WASM=false
ENV WASM=${BUILD_WASM}
RUN if [ "$WASM" = "true" ]; then \
    wget -P /root https://github.com/WebAssembly/binaryen/releases/download/version_116/binaryen-version_116-x86_64-linux.tar.gz && \
    tar -xzf /root/binaryen-version_116-x86_64-linux.tar.gz -C /root && \
    cp /root/binaryen-version_116/bin/* /usr/local/bin; \
    fi

# checkout and build the specified tag of Namada binaries
ARG NAMADA_TAG=main
ENV NAMADA_TAG=${NAMADA_TAG}
RUN git clone https://github.com/anoma/namada.git
WORKDIR /app/namada
RUN git checkout ${NAMADA_TAG}

RUN make build-release
RUN if [ "$WASM" = "true" ]; then \
    rustup target add wasm32-unknown-unknown && \
    make build-wasm-scripts; \
    fi

# build cometbft
FROM golang:1.20.0 as tendermint-builder
WORKDIR /app

RUN git clone -b v0.37.11 --single-branch https://github.com/cometbft/cometbft.git && cd cometbft && make build

FROM debian:bullseye-slim AS runtime
#ENV NAMADA_BASE_DIR=/.namada
#ENV NAMADA_LOG_COLOR=false

RUN apt-get update && apt-get install libcurl4-openssl-dev curl jq iproute2 procps python3 python3-pip -y && apt-get clean
RUN pip install toml

# copy namada and cometbft binaries, and wasm files

COPY --from=builder /app/namada/wasm/*.wasm /app/namada/wasm/*.json /wasm/

COPY --from=builder /app/namada/target/release/namada /usr/local/bin
COPY --from=builder /app/namada/target/release/namadan /usr/local/bin
COPY --from=builder /app/namada/target/release/namadaw /usr/local/bin
COPY --from=builder /app/namada/target/release/namadac /usr/local/bin
COPY --from=tendermint-builder /app/cometbft/build/cometbft /usr/local/bin

EXPOSE 26656
EXPOSE 26660
EXPOSE 26659
EXPOSE 26657

ENTRYPOINT ["/usr/local/bin/namada"]
CMD ["--version"]
