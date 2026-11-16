#!/usr/bin/env bash
# Uso: ./k8s/deploy.sh [replicas]    (por defecto 1)
set -euo pipefail
cd "$(dirname "$0")/.."
REPLICAS="${1:-1}"
KUBECTL="${KUBECTL:-kubectl}"   # en MicroK8s: KUBECTL="microk8s kubectl"

$KUBECTL apply -f k8s/00-namespace.yaml
$KUBECTL -n catalog create configmap db-init --from-file=init.sql=db/init.sql \
  --dry-run=client -o yaml | $KUBECTL apply -f -
$KUBECTL apply -f k8s/10-postgres.yaml
$KUBECTL -n catalog rollout status deploy/db --timeout=180s
$KUBECTL apply -f k8s/20-api.yaml
$KUBECTL -n catalog scale deploy/api --replicas="$REPLICAS"
$KUBECTL -n catalog rollout status deploy/api --timeout=180s
$KUBECTL -n catalog get pods -o wide
echo "API disponible en http://<IP-de-cualquier-nodo>:30080/health"
