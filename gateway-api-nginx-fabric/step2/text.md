# Crear un Gateway compartido

El equipo de plataforma publica **un único Gateway** en el namespace `infra` y decide qué
namespaces pueden colgar rutas de él mediante `allowedRoutes`.

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: cafe-gw
  namespace: infra
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            shared-gateway-access: "true"
YAML
```{{exec}}

Opciones de `allowedRoutes.namespaces.from`:

| Valor | Significado |
|---|---|
| `Same` (por defecto) | Solo rutas del mismo namespace que el Gateway |
| `All` | Rutas de cualquier namespace |
| `Selector` | Solo namespaces cuyas labels coincidan con el selector |

### Observa el aprovisionamiento

```bash
kubectl get gateway -n infra
kubectl get deploy,svc,pods -n infra
```{{exec}}

NGF creó `cafe-gw-nginx` (Deployment y Service). Espera a que el Gateway esté `PROGRAMMED=True`:

```bash
kubectl wait -n infra gateway/cafe-gw --for=condition=Programmed --timeout=120s
kubectl get svc cafe-gw-nginx -n infra
```{{exec}}

El Service expone el puerto 80 en el NodePort **30080**. Guarda la IP del nodo para las pruebas:

```bash
export NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
curl -s -o /dev/null -w "%{http_code}\n" http://$NODE_IP:30080/
```{{exec}}

Un `404` es correcto: el Gateway escucha, pero aún no tiene rutas.

> **Condiciones clave del Gateway:** `Accepted` (la configuración es válida) y `Programmed`
> (el data plane ya la aplicó). En el examen, `kubectl describe gateway` es tu mejor amigo.
