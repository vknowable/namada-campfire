## namada
1. pick a commit/tag to build, eg: `NAMADA_TAG=v0.35.1`
2. build container: `docker build -t namada:$NAMADA_TAG --build-arg NAMADA_TAG=$NAMADA_TAG --build-arg BUILD_WASM=true .`