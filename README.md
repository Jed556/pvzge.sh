# PvZ2 Gardendless Docker Helper

`pvzge.sh` is a helper script for managing the **PvZ2 Gardendless** Docker container. It wraps common Docker commands so you can start, stop, update, or delete the container with a single command.

## Requirements

- Docker Engine is installed and running
- Bash-compatible shell (e.g., Git Bash on Windows, WSL, Linux terminal)

## Quick Start

```bash
# start (or create) the container on the default port 8080
./pvzge.sh start

# open the game
# -> http://localhost:8080
```

To bind to a different host port (for example port 80):

```bash
./pvzge.sh start 80
```

## Available Commands

| Command | Description |
|---------|-------------|
| `./pvzge.sh start [HOST_PORT]` | Starts the container. If it does not exist, the script creates it using the `gaozih/pvzge:latest` image. Defaults to host port 8080. |
| `./pvzge.sh stop` | Stops the running container if present. |
| `./pvzge.sh update [HOST_PORT]` | Pulls the latest image, removes the existing container **including save data**, and recreates it. |
| `./pvzge.sh delete` | Stops and removes the container and attempts to delete the image **including save data** locally. |
| `./pvzge.sh status` | Shows Docker status for the container. |
| `./pvzge.sh help` | Displays inline usage information. |

## Data Safety

`update` and `delete` will remove the container and **your progress**. Always export your save file from the game before running these commands.

## Troubleshooting

- **"Docker CLI not found"** – Make sure Docker is installed and added to your PATH.
- **"Docker daemon is not running"** – Start Docker service before using the script.
- **Permission errors on Windows** – Run the script from Bash, and ensure the user can access Docker.

## Customization

The script defaults are set near the top of `pvzge.sh`:

```bash
IMAGE="gaozih/pvzge:latest"
CONTAINER="pvzge"
DEFAULT_HOST_PORT="8080"
CONTAINER_PORT="80"
```

Adjust these values if you host multiple instances or rely on a different image tag.


## PvZGE Docker Hub

Docker Hub URL: https://hub.docker.com/r/gaozih/pvzge
