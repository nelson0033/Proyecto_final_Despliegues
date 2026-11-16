# Proyecto Final — Comportamiento de una API bajo distintos escenarios de despliegue

Aplicación: API REST de catálogo (FastAPI + PostgreSQL, 20.000 registros).
Escenarios: Docker Compose (1 máquina) y Kubernetes/K3s con 1, 2 y 3 nodos × 1, 2, 3 réplicas.

```
app/            código de la API + Dockerfile
db/init.sql     esquema y 20.000 registros
docker-compose.yml
k8s/            manifiestos YAML + deploy.sh
docs/CLUSTER_SETUP.md   montaje de K3s 1/2/3 nodos
jmeter/         plan.jmx + run_experiment.sh
results/        archivos .jtl generados por JMeter
notebook/analisis_despliegues.ipynb
```

## Pasos
1. **Docker Compose** (máquina A): `docker compose up -d --build` → `curl http://<IP_A>:8000/health`
2. **Pruebas** (máquina B con JMeter): `./jmeter/run_experiment.sh docker 1 1 <IP_A> 8000`
3. **K3s** (ver `docs/CLUSTER_SETUP.md`): para cada número de nodos (1, 2, 3) y réplicas (1, 2, 3):
   ```bash
   kubectl -n catalog scale deploy/api --replicas=<R>
   ./jmeter/run_experiment.sh k8s <NODOS> <R> <IP_NODO> 30080
   ```
4. Copia los `.jtl` a `results/` y abre el notebook (Jupyter o Colab); ejecútalo y completa las secciones de análisis, conclusiones y recomendaciones con tus datos.

Variables útiles del script: `THREAD_LEVELS="10 50 100 200"`, `DURATION=90`, `RAMPUP=10`.
