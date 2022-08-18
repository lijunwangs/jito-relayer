#!/usr/bin/env sh
set -e

# dev or testnet
ENV=$1
ENV_FILE=./env/.env.${ENV}

TAG=$(git describe --match=NeVeRmAtCh --always --abbrev=8 --dirty)
ORG="jitolabs"

if [ -f "$ENV_FILE" ]; then
  export $(cat "$ENV_FILE" | grep -v '#' | awk '/=/ {print $1}')
else
  echo "Missing .env file"
  exit 0
fi

# A little hacky, but .env files can't execute so this is the best we have for now
if [ "$ENV" = "dev" ]; then
  if [ "$(uname)" = "Darwin" ]; then
    RPC_SERVERS=http://docker.for.mac.localhost:8899
    WEBSOCKET_SERVERS=ws://docker.for.mac.localhost:8900
    BLOCK_ENGINE_AUTH_SERVICE_URL=http://docker.for.mac.localhost:${BLOCK_ENGINE_AUTH_SERVICE_PORT}
    BLOCK_ENGINE_URL=http://docker.for.mac.localhost:${BLOCK_ENGINE_PORT}
  elif [ "$(expr substr $(uname -s) 1 5)" = "Linux" ]; then
    RPC_SERVERS=http://172.17.0.1:8899
    WEBSOCKET_SERVERS=ws://172.17.0.1:8900
    BLOCK_ENGINE_AUTH_SERVICE_URL=http://172.17.0.1:${BLOCK_ENGINE_AUTH_SERVICE_PORT}
    BLOCK_ENGINE_URL=http://172.17.0.1:${BLOCK_ENGINE_PORT}
  else
    echo "unsupported testing platform, exiting"
    exit 1
  fi
elif [ "$ENV" != "mainnet"  ] && [ "$ENV" != "testnet" ]; then
  echo "ERROR: must run ./b [dev | testnet | mainnet]"
  exit 2
fi

COMPOSE_DOCKER_CLI_BUILD=1 \
  DOCKER_BUILDKIT=1 \
  RPC_SERVERS="${RPC_SERVERS}" \
  WEBSOCKET_SERVERS="${WEBSOCKET_SERVERS}" \
  BLOCK_ENGINE_URL="${BLOCK_ENGINE_URL}" \
  BLOCK_ENGINE_AUTH_SERVICE_URL="${BLOCK_ENGINE_AUTH_SERVICE_URL}" \
  TAG="${TAG}" \
  ORG="${ORG}" \
  docker compose --env-file "${ENV_FILE}" build --progress=plain

COMPOSE_DOCKER_CLI_BUILD=1 \
  DOCKER_BUILDKIT=1 \
  RPC_SERVERS="${RPC_SERVERS}" \
  WEBSOCKET_SERVERS="${WEBSOCKET_SERVERS}" \
  BLOCK_ENGINE_URL="${BLOCK_ENGINE_URL}" \
  BLOCK_ENGINE_AUTH_SERVICE_URL="${BLOCK_ENGINE_AUTH_SERVICE_URL}" \
  TAG="${TAG}" \
  ORG="${ORG}" \
  docker compose --env-file "${ENV_FILE}" up --remove-orphans
