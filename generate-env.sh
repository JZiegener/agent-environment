#!/usr/bin/env bash
# generate-env.sh
# Copies .env.example to .env and populates required secrets

set -euo pipefail

EXAMPLE=.env.example
TARGET=.env

# Copy example to target
cp "$EXAMPLE" "$TARGET"

# Helper to generate a secret
# $1: type 'hex' or 'base64'
# $2: length in bytes
rand() {
    local type=$1
    local len=$2
    if [[ "$type" == "hex" ]]; then
        openssl rand -hex $((len/2))
    elif [[ "$type" == "base64" ]]; then
        openssl rand -base64 $len
    else
        echo "Unsupported type" >&2
        exit 1
    fi
}

# Generate secrets
SALT=$(rand base64 32)
ENCRYPTION_KEY=$(rand hex 32)  # 32 bytes = 64 hex chars  (generated with openssl rand -hex 32)
NEXTAUTH_SECRET=$(rand base64 32)
REDIS_AUTH=$(rand base64 32)
POSTGRES_PASSWORD=$(openssl rand -base64 12 | tr -dc A-Za-z0-9)

MINIO_ROOT_PASSWORD=$(rand base64 32)
CLICKHOUSE_PASSWORD=$(rand base64 32)
S3_EVENT_SECRET=$(rand base64 32)
S3_MEDIA_SECRET=$(rand base64 32)
S3_BATCH_SECRET=$(rand base64 32)

LANGFUSE_INIT_USER_PASSWORD=$(openssl rand -base64 12 | tr -dc A-Za-z0-9)

# Replace the value for a given key in $TARGET
replace() {
    local key=$1
    local value=$2
    sed -i "s|^${key}=.*|${key}=${value}|" "$TARGET"
}

replace SALT "$SALT"
replace ENCRYPTION_KEY "$ENCRYPTION_KEY"
replace NEXTAUTH_SECRET "$NEXTAUTH_SECRET"
replace REDIS_AUTH "$REDIS_AUTH"
replace MINIO_ROOT_PASSWORD "$MINIO_ROOT_PASSWORD"
replace CLICKHOUSE_PASSWORD "$CLICKHOUSE_PASSWORD"
replace LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY "$S3_EVENT_SECRET"
replace LANGFUSE_S3_MEDIA_UPLOAD_SECRET_ACCESS_KEY "$S3_MEDIA_SECRET"
replace POSTGRES_PASSWORD "$POSTGRES_PASSWORD"

# Generate RSA key pair for Langfuse project
openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:2048 \
  && openssl rsa -pubout -in private_key.pem -out public_key.pem
PROJECT_PUBLIC_KEY=$(cat public_key.pem | tr -d '\n')
PROJECT_SECRET_KEY=$(cat private_key.pem | tr -d '\n')
replace LANGFUSE_INIT_PROJECT_PUBLIC_KEY "$PROJECT_PUBLIC_KEY"
replace LANGFUSE_INIT_PROJECT_SECRET_KEY "$PROJECT_SECRET_KEY"
rm -f private_key.pem public_key.pem

replace LANGFUSE_INIT_USER_PASSWORD "$LANGFUSE_INIT_USER_PASSWORD"

# Duplicate RSA and password generation removed to avoid redundancy



chmod +x "$0"
echo "Generated .env file with secrets successfully."
