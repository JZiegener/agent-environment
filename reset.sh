#!/usr/bin/env bash

set -euo pipefail

# 1. Clean up Docker resources
# Stop all running containers in this compose file
# The compose file location is the repo root

# Find all containers created by this compose based on labels
COMPOSE_PROJECT_NAME=$(docker compose config --project-name 2>/dev/null || echo "agent-environment")

# Stop and remove containers
if docker ps -a --filter "label=com.docker.compose.project=${COMPOSE_PROJECT_NAME}" | grep -q .; then
  echo "Stopping and removing existing containers..."
  docker compose down
else
  echo "No existing containers found for project ${COMPOSE_PROJECT_NAME}"
fi

# Remove volumes that belong to this compose project
# The volumes are named in the docker-compose file; we can delete all by down -v
# But just in case we delete explicitly defined volumes
for vol in $(docker volume ls -q --filter "label=com.docker.compose.project=${COMPOSE_PROJECT_NAME}" | grep -E "langfuse_" ); do
  echo "Removing volume $vol"
  docker volume rm "$vol"
done

# 2. Delete the .env file if it exists
if [ -f .env ]; then
  echo "Removing existing .env file"
  rm .env
else
  echo ".env file not present"
fi

# 3. Generate new .env
if [ -x ./generate-env.sh ]; then
  echo "Running generate-env.sh to create new .env"
  ./generate-env.sh
else
  echo "generate-env.sh not found or not executable"
fi

# 4. Bring up services
echo "Starting Docker compose..."
# Use -d for detached mode
# We keep the -V flag to create volumes defined in compose, since we just removed them

docker compose up -d --wait

# Show status

docker compose ps

# Done

echo "Reset complete. All services are up and running."
