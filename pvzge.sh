#!/usr/bin/env bash
# pvzge.sh — start | stop | update | delete PvZ2 Gardendless docker container
# Usage:
#   ./pvzge.sh start [HOST_PORT]
#   ./pvzge.sh stop
#   ./pvzge.sh update [HOST_PORT]
#   ./pvzge.sh delete
#
# Default host port: 8080
# Container name: pvzge
# Image: gaozih/pvzge:latest

set -u

IMAGE="gaozih/pvzge:latest"
CONTAINER="pvzge"
DEFAULT_HOST_PORT="8080"
CONTAINER_PORT="80"

# Helpers
info()  { printf "\e[32m[INFO]\e[0m %s\n" "$*"; }
warn()  { printf "\e[33m[WARN]\e[0m %s\n" "$*"; }
error() { printf "\e[31m[ERROR]\e[0m %s\n" "$*" >&2; }
die()   { error "$*"; exit 1; }

check_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    die "Docker CLI not found. Install Docker and try again."
  fi
  if ! docker info >/dev/null 2>&1; then
    die "Docker daemon is not running or you don't have permission. Start Docker or run with appropriate permissions."
  fi
}

container_exists() {
  docker ps -a --format '{{.Names}}' | grep -xq "$CONTAINER"
}

container_running() {
  docker ps --format '{{.Names}}' | grep -xq "$CONTAINER"
}

run_container() {
  local host_port="$1"
  info "Creating and starting container '$CONTAINER' mapping ${host_port}:${CONTAINER_PORT}..."
  docker run --name "$CONTAINER" -d -p "${host_port}:${CONTAINER_PORT}" "$IMAGE" \
    >/dev/null && info "Container started. Play at: http://localhost:${host_port}" || error "Failed to start container. See 'docker logs $CONTAINER'."
}

start() {
  local host_port="${1:-$DEFAULT_HOST_PORT}"
  check_docker
  if container_running; then
    info "Container '$CONTAINER' is already running. Access it at: http://localhost:${host_port}"
    return 0
  fi
  if container_exists; then
    info "Container exists but not running. Starting existing container..."
    docker start "$CONTAINER" >/dev/null && info "Started container. Visit http://localhost:${host_port}" || error "Failed to start container. See 'docker logs $CONTAINER'."
  else
    run_container "$host_port"
  fi
}

stop() {
  check_docker
  if container_running; then
    info "Stopping container '$CONTAINER'..."
    docker stop "$CONTAINER" >/dev/null && info "Stopped." || error "Failed to stop container."
  else
    warn "Container '$CONTAINER' is not running."
  fi
}

_update_or_recreate() {
  local host_port="$1"
  check_docker

  if container_running; then
    info "Stopping running container..."
    docker stop "$CONTAINER" >/dev/null || warn "Could not stop container cleanly."
  fi

  if container_exists; then
    info "Removing old container..."
    docker rm "$CONTAINER" >/dev/null || warn "Could not remove container. You may need to remove it manually."
  fi

  info "Pulling latest image: $IMAGE"
  docker pull "$IMAGE" || die "docker pull failed."

  run_container "$host_port"
}

confirm_danger() {
  echo
  warn "This action may remove game data. Make sure you EXPORT your save file before proceeding."
  while true; do
    # -p prints prompt on same line, read returns empty string on Enter
    read -r -p "Proceed? [y/N] " yn
    case "$yn" in
      [Yy]* ) break ;;          # yes -> continue
      ""|[Nn]* ) die "Aborting." ;; # Enter or no -> abort
      * ) echo "Please answer y or n." ;; 
    esac
  done
}


update() {
  local host_port="${1:-$DEFAULT_HOST_PORT}"
  confirm_danger
  _update_or_recreate "$host_port"
}

delete() {
  check_docker
  confirm_danger
  if container_running; then
    info "Stopping container..."
    docker stop "$CONTAINER" >/dev/null || warn "Could not stop container."
  fi
  if container_exists; then
    info "Removing container..."
    docker rm "$CONTAINER" >/dev/null || warn "Could not remove container."
  else
    warn "Container does not exist."
  fi

  info "Removing image '$IMAGE' locally (if present)..."
  # Attempt to remove image. Not fatal if it fails (images may be shared or used by other containers).
  docker image rm "$IMAGE" >/dev/null 2>&1 && info "Image removed." || warn "Could not remove image (it may not exist, or is used by other images/containers)."
  info "Delete complete."
}

status() {
  check_docker
  docker ps -a --filter "name=${CONTAINER}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Main
cmd="${1:-help}"
arg_port="${2:-}"

case "$cmd" in
  start)
    start "$arg_port"
    ;;
  stop)
    stop
    ;;
  update)
    update "$arg_port"
    ;;
  delete)
    delete
    ;;
  status)
    status
    ;;
  help|--help|-h|"")
    cat <<EOF
pvzge.sh — control script for PvZ2 Gardendless Docker container

Commands:
  start [HOST_PORT]   Start (or create+start) container. Default port: ${DEFAULT_HOST_PORT}
  stop                Stop the running container
  update [HOST_PORT]  Pull latest image, remove old container, recreate. WARNING: will remove save data.
  delete              Remove container and try to remove image. WARNING: will remove save data.
  status              Show container status
  help                Show this help

Examples:
  ./pvzge.sh start        # start on 8080
  ./pvzge.sh start 80     # start on host port 80
  ./pvzge.sh update 8080  # update and recreate, host port 8080
  ./pvzge.sh delete       # remove container and image (requires typing CONFIRM)
EOF
    ;;
  *)
    error "Unknown command: $cmd"
    echo "Run ./pvzge.sh help"
    exit 2
    ;;
esac
