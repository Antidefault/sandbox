#!/usr/bin/env bash

# Default values
CONTAINER_RUNTIME="podman"
NETWORK="sandbox"
PORTS=""
CONTAINER_NAME=""
COMMAND=""
WORKSPACE_DIR="/workspace"

# Function to display usage
usage() {
    echo "Usage: $0 [suffix] [OPTIONS]"
    echo "Options:"
    echo "  -n, --network NETWORK    Container network to use"
    echo "  -p, --ports PORTS        Comma-separated list of ports (e.g., 8080,3000,5432)"
    echo "  -w, --workspace DIR      Container workspace directory (default: /workspace)"
    echo "  --name NAME              Container name"
    echo "  --cmd COMMAND            Command to run"
    echo "  --docker                 Use docker instead of podman"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Example: $0 myapp --network sandbox --name frontend --ports 8080,3000"
    exit 1
}

# Check if first argument is a suffix or an option
SUFFIX=""
if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
    SUFFIX="$1"
    shift
fi

# Parse remaining command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--network)
            NETWORK="$2"
            shift 2
            ;;
        -p|--ports)
            PORTS="$2"
            shift 2
            ;;
        -w|--workspace)
            WORKSPACE_DIR="$2"
            shift 2
            ;;
        --name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        --cmd)
            COMMAND="$2"
            shift 2
            ;;
        --docker)
            CONTAINER_RUNTIME="docker"
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "Error: Unknown option $1"
            usage
            ;;
        *)
            echo "Error: Unexpected positional argument '$1'. Only suffix is allowed as first argument."
            usage
            ;;
    esac
done

# Determine image name and build strategy
if [ -n "$SUFFIX" ]; then
    # Use pre-built image
    IMAGE_NAME="sandbox-$SUFFIX"
    
    # Check if the container image exists
    if ! $CONTAINER_RUNTIME image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
        echo "Error: $CONTAINER_RUNTIME image '$IMAGE_NAME' not found."
        echo "Available sandbox images:"
        $CONTAINER_RUNTIME images --format "{{.Repository}}" | grep "^sandbox-" | sed 's/^sandbox-//' || echo "  None found"
        exit 1
    fi
else
    # Use Dockerfile in current directory
    if [ ! -f "Dockerfile" ]; then
        echo "Error: No suffix provided and no Dockerfile found in current directory."
        echo "Available sandbox images:"
        $CONTAINER_RUNTIME images --format "{{.Repository}}" | grep "^sandbox-" | sed 's/^sandbox-//' || echo "  None found"
        exit 1
    fi
    
    # Create hash-based image name
    HASH=$(sha256sum Dockerfile | cut -d' ' -f1 | head -c 12)
    IMAGE_NAME="sandbox-dockerfile:$HASH"
    
    # Build image if it doesn't exist
    if ! $CONTAINER_RUNTIME image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
        echo "Building image from Dockerfile..."
        $CONTAINER_RUNTIME build -t "$IMAGE_NAME" .
        if [ $? -ne 0 ]; then
            echo "Error: Failed to build image from Dockerfile"
            exit 1
        fi
    else
        echo "Using cached image: $IMAGE_NAME"
    fi
fi

# Build container run arguments
CONTAINER_ARGS="-it --rm -v $(pwd):$WORKSPACE_DIR"

# Add GPU support for podman
if [ "$CONTAINER_RUNTIME" = "podman" ]; then
    CONTAINER_ARGS="$CONTAINER_ARGS --device nvidia.com/gpu=all"
fi

# Add container name if specified
if [ -n "$CONTAINER_NAME" ]; then
    CONTAINER_ARGS="$CONTAINER_ARGS --name $CONTAINER_NAME"
fi

# Add network if specified
if [ -n "$NETWORK" ]; then
    CONTAINER_ARGS="$CONTAINER_ARGS --network $NETWORK"
fi

# Add port mappings if specified
if [ -n "$PORTS" ]; then
    IFS=',' read -ra PORT_ARRAY <<< "$PORTS"
    for port in "${PORT_ARRAY[@]}"; do
        # Trim whitespace
        port=$(echo "$port" | xargs)
        CONTAINER_ARGS="$CONTAINER_ARGS -p $port:$port"
    done
fi

# Run container command
if [ -n "$COMMAND" ]; then
    # Run command
    $CONTAINER_RUNTIME run $CONTAINER_ARGS "$IMAGE_NAME" zsh -c "$COMMAND"
else
    # Default behavior
    $CONTAINER_RUNTIME run $CONTAINER_ARGS "$IMAGE_NAME"
fi