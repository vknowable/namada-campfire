FROM node:22-alpine AS build-env

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

# copy the .env file
COPY apps/faucet/.env /root/namada-interface/apps/faucet/.env

WORKDIR /root/namada-interface
#RUN yarn install

# build `shared` package
WORKDIR /root/namada-interface/packages/shared
RUN yarn add typescript
RUN yarn
#RUN yarn global add typescript
RUN cargo install -f wasm-bindgen-cli
RUN yarn wasm:build

# build
RUN yarn
WORKDIR /root/namada-interface/apps/faucet
ENV NODE_ENV=production
RUN yarn build

#########################################

# final image
FROM nginx:alpine

# copy files from build stage
COPY --from=build-env /root/namada-interface/apps/faucet/docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build-env /root/namada-interface/apps/faucet/build   /usr/share/nginx/html
