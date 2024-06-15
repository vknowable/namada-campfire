FROM node:18.17.1-alpine AS build-env

ARG APP_NAME=namadillo
ARG REPO_NAME=namada-interface

# install dependencies
ENV PACKAGES add git python3 alpine-sdk clang pkgconfig openssl-dev protoc protobuf-dev build-base curl
RUN apk --update --no-cache $PACKAGES

# install rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup target add wasm32-unknown-unknown
RUN  curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh

# copy source files
RUN mkdir /root/$REPO_NAME
WORKDIR /root/$REPO_NAME
COPY . .

# copy the .env file
COPY apps/namadillo/.env /root/namada-interface/apps/namadillo/.env

# build
RUN yarn
WORKDIR /root/$REPO_NAME/apps/$APP_NAME
RUN yarn build

#########################################

# final image
FROM nginx:alpine

ARG APP_NAME=namadillo
ARG REPO_NAME=namada-interface

# copy files from build stage
COPY --from=build-env /root/$REPO_NAME/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build-env /root/$REPO_NAME/apps/$APP_NAME/dist   /usr/share/nginx/html
