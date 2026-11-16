#!/usr/bin/env bash
# Ejecuta la batería de cargas contra un escenario ya desplegado.
#
# Uso:
#   ./jmeter/run_experiment.sh <escenario> <nodos> <replicas> <host> <puerto> [repeticiones]
# Ejemplos:
#   ./jmeter/run_experiment.sh docker 1 1 10.0.0.5 8000
#   ./jmeter/run_experiment.sh k8s    2 3 10.0.0.6 30080 3
#
# Genera results/<escenario>_n<nodos>_r<replicas>_t<hilos>_rep<k>.jtl
set -euo pipefail
cd "$(dirname "$0")/.."

SCENARIO="$1"; NODES="$2"; REPLICAS="$3"; HOST="$4"; PORT="$5"; REPS="${6:-3}"
THREAD_LEVELS="${THREAD_LEVELS:-10 50 100 200}"
DURATION="${DURATION:-90}"      # segundos por corrida
RAMPUP="${RAMPUP:-10}"
JMETER="${JMETER:-jmeter}"

mkdir -p results
for t in $THREAD_LEVELS; do
  for r in $(seq 1 "$REPS"); do
    OUT="results/${SCENARIO}_n${NODES}_r${REPLICAS}_t${t}_rep${r}.jtl"
    echo ">> $OUT"
    rm -f "$OUT"
    "$JMETER" -n -t jmeter/plan.jmx -l "$OUT" \
      -Jhost="$HOST" -Jport="$PORT" -Jthreads="$t" -Jrampup="$RAMPUP" -Jduration="$DURATION" \
      -Jjmeter.save.saveservice.output_format=csv
    sleep 15   # enfriamiento entre corridas
  done
done
echo "Listo. Resultados en results/"
