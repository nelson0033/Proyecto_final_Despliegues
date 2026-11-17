#!/usr/bin/env bash
# Despliega la API en Kubernetes. PostgreSQL corre FUERA del clúster (Docker en la VM A).
# Uso: DB_HOST=<IP_VM_A> bash k8s/deploy.sh [replicas]
#   p. ej.: DB_HOST=192.168.1.7 KUBECTL="sudo k3s kubectl" bash k8s/deploy.sh 1
set -euo pipefail
cd "$(dirname "$0")/.."
REPLICAS="${1:-1}"
: "${DB_HOST:?Define DB_HOST con la IP de la VM donde corre PostgreSQL (docker compose -f docker-compose.db.yml up -d)}"
KUBECTL="${KUBECTL:-kubectl}"   # en K3s: KUBECTL="sudo k3s kubectl"

$KUBECTL apply -f k8s/00-namespace.yaml

# Service "db" sin selector + Endpoints manuales -> la API sigue usando DB_HOST=db
cat <<YAML | $KUBECTL apply -f -
apiVersion: v1
kind: Service
metadata:
  name: db
  namespace: catalog
spec:
  ports:
    - port: 5432
      targetPort: 5432
---
apiVersion: v1
kind: Endpoints
metadata:
  name: db
  namespace: catalog
subsets:
  - addresses:
      - ip: ${DB_HOST}
    ports:
      - port: 5432
YAML

$KUBECTL apply -f k8s/20-api.yaml
$KUBECTL -n catalog scale deploy/api --replicas="$REPLICAS"
$KUBECTL -n catalog rollout status deploy/api --timeout=180s
$KUBECTL -n catalog get pods -o wide
echo "API disponible en http://<IP-de-cualquier-nodo>:30080/health"
