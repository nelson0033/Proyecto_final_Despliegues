# Montaje de los clústeres (K3s, 1 / 2 / 3 nodos)

Requisitos: máquinas Linux (VMs en la nube o locales) en la misma red; la máquina de JMeter es **otra** distinta.

## 1 nodo
```bash
curl -sfL https://get.k3s.io | sh -
sudo k3s kubectl get nodes
```

## Añadir nodos (2 y 3 nodos)
En el servidor obtén el token e IP:
```bash
sudo cat /var/lib/rancher/k3s/server/node-token
hostname -I
```
En cada worker:
```bash
curl -sfL https://get.k3s.io | K3S_URL=https://<IP_SERVIDOR>:6443 K3S_TOKEN=<TOKEN> sh -
```
Verifica con `sudo k3s kubectl get nodes` (deben aparecer 2 o 3 en `Ready`).

## Imagen de la aplicación en todos los nodos
Opción A (registry, recomendada): `docker build -t <usuario>/catalog-api:1.0 app && docker push ...` y cambia `image:` en `k8s/20-api.yaml`.
Opción B (sin registry): en cada nodo
```bash
docker save catalog-api:latest | sudo k3s ctr images import -
```

## Despliegue
```bash
KUBECTL="sudo k3s kubectl" ./k8s/deploy.sh 1
KUBECTL="sudo k3s kubectl" $KUBECTL -n catalog scale deploy/api --replicas=2   # o 3
```
La API queda en `http://<IP-cualquier-nodo>:30080`.

## Recomendaciones metodológicas
- Usa nodos con las **mismas** características (vCPU/RAM) en todos los escenarios.
- Mantén iguales los `resources` del Deployment en todas las pruebas.
- Repite cada prueba al menos 3 veces y descarta el calentamiento (el plan ya lo hace).
- Para quitar el efecto de la BD como cuello de botella o analizarlo, documenta en qué nodo cae el pod `db` (`kubectl get pods -o wide`).
