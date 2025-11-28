#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Building Docker image hello-candidate"
docker build -t hello-candidate "$ROOT_DIR"

echo "==> Applying Terraform configuration"
terraform -chdir="$ROOT_DIR/infra" init
terraform -chdir="$ROOT_DIR/infra" apply -auto-approve

echo "==> Deploying Helm release"
helm upgrade --install hello-candidate "$ROOT_DIR/charts/hello-candidate" -n devops-challenge

echo "All done!"

