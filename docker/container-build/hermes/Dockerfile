FROM rust:bookworm AS builder

WORKDIR /root

RUN apt-get update && apt-get install -y \
    build-essential \
    clang-tools-14 \
    git \
    libssl-dev \
    pkg-config \
    protobuf-compiler \
    libudev-dev \
    && apt-get clean

RUN git clone -b v1.10.5-namada-beta18 https://github.com/heliaxdev/hermes 
RUN cd hermes && cargo build --release

FROM ubuntu:latest AS runtime

RUN apt-get update && apt-get install -y python3 curl nano ca-certificates && apt-get clean
RUN update-ca-certificates

WORKDIR /app

RUN curl -o /app/masp-spend.params -L https://github.com/anoma/masp-mpc/releases/download/namada-trusted-setup/masp-spend.params\?raw\=true
RUN curl -o /app/masp-output.params -L https://github.com/anoma/masp-mpc/releases/download/namada-trusted-setup/masp-output.params?raw=true
RUN curl -o /app/masp-convert.params -L https://github.com/anoma/masp-mpc/releases/download/namada-trusted-setup/masp-convert.params?raw=true

ENV NAMADA_MASP_PARAMS_DIR=/app

COPY --from=builder /root/hermes/target/release/hermes /usr/bin/hermes

COPY config-generator.py add-keys.py config-template.toml.template .
COPY --chmod=0755 entrypoint.sh .

ENTRYPOINT ["sh", "entrypoint.sh"]