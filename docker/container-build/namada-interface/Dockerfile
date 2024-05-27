FROM node:18.17.1-alpine AS build-env

# install dependencies
ENV PACKAGES add git python3 alpine-sdk clang pkgconfig openssl-dev protoc protobuf-dev build-base curl
RUN apk --update --no-cache $PACKAGES

# install rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup target add wasm32-unknown-unknown
RUN  curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh

# copy source files
RUN mkdir /root/namada-interface
WORKDIR /root/namada-interface
COPY . .

# build
RUN yarn
WORKDIR /root/namada-interface/apps/namada-interface
RUN yarn build

#########################################

# final image
FROM nginx:alpine

# copy files from build stage
COPY --from=build-env /root/namada-interface/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build-env /root/namada-interface/apps/namada-interface/build   /usr/share/nginx/html