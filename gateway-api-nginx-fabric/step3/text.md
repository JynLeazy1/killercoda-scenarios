# HTTPRoute y allowedRoutes entre namespaces

El equipo de aplicaciones (namespace `cafe`) crea sus rutas apuntando al Gateway de `infra`
mediante `parentRefs`. Vamos a crear **dos rutas independientes** para el mismo host.

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: coffee
  namespace: cafe
spec:
  parentRefs:
  - name: cafe-gw
    namespace: infra
  hostnames:
  - cafe.example
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /coffee
    backendRefs:
    - name: coffee-v1
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: tea
  namespace: cafe
spec:
  parentRefs:
  - name: cafe-gw
    namespace: infra
  hostnames:
  - cafe.example
  rules:
  - matches:
    - path:
        type: Exact
        value: /tea
    backendRefs:
    - name: tea
      port: 80
YAML
```{{exec}}

### ¿Funciona?

```bash
curl -s -o /dev/null -w "%{http_code}\n" -H "Host: cafe.example" http://$NODE_IP:30080/coffee
```{{exec}}

Sigue devolviendo `404`. Revisa el **status** de la ruta: ahí es donde el controlador te explica qué pasa.

```bash
kubectl get httproute coffee -n cafe -o jsonpath='{range .status.parents[*].conditions[*]}{.type}={.status} ({.reason}){"\n"}{end}'
```{{exec}}

Verás `Accepted=False (NotAllowedByListeners)`: el listener solo admite namespaces con la label
`shared-gateway-access=true`.

### Tarea

Añade la label al namespace `cafe` para que el Gateway acepte sus rutas.

<details>
<summary>Solución</summary>

```bash
kubectl label namespace cafe shared-gateway-access=true
```{{exec}}

</details>

Comprueba de nuevo (el controlador puede tardar unos segundos en reconciliar y recargar NGINX;
si ves un `404`, repite el comando):

```bash
kubectl get httproute -n cafe
curl -s -H "Host: cafe.example" http://$NODE_IP:30080/coffee | grep -E '"(path|pod)"'
curl -s -H "Host: cafe.example" http://$NODE_IP:30080/tea | grep -E '"(path|pod)"'
curl -s -o /dev/null -w "/tea/extra -> %{http_code}\n" -H "Host: cafe.example" http://$NODE_IP:30080/tea/extra
```{{exec}}

> **Tipos de path match:** `PathPrefix` (por segmentos: `/coffee` coincide con `/coffee/latte` pero
> **no** con `/coffeeshop`), `Exact` y `RegularExpression` (soporte dependiente de la implementación).
